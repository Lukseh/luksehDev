import { Elysia } from "elysia";
import cors from '@elysiajs/cors'
import { swagger } from '@elysiajs/swagger'
import { Type } from '@sinclair/typebox';
import { RedisClient } from "bun";
import { PrismaClient } from '@prisma/client'

const db = new PrismaClient()

const client = new RedisClient();


// If you want to check connectivity, you can use:
async function checkRedisConnection() {
  try {
    await client.ping();
    console.log("Redis connection successful.");
  } catch (err) {
    console.error("Redis connection failed:", err);
  }
}
checkRedisConnection();

const refreshTreshold = 21600; // 6 hours


const JWT_SECRET = process.env.JWT_SECRET || "JWT_SECRET";

type RedisStoreLinkedIn = {
  full_name: string,
  name: string,
  last_name: string,
  pfp: string,
  timestamp: number,
}
type RedisStoreGithub = {
  name: string,
  url: string,
  homepage: string | boolean,
  language: string,
  license: string | boolean,
  archived: string | boolean,
  description: string | boolean,
  timestamp: number,
}
type RedisStoreDiscord = {
  username: string,
  avatar: string,
  accent_color: number,
  banner_color: string,
  timestamp: number,
}
type RedisStoreSpotify = {
  timestamp: number,
  data: string
}

async function purgeCache() {
  const githubKeys = await client.keys("/github:*");
  if (githubKeys.length > 0) {
    await client.del(...githubKeys);
  }
  await client.del("/linkedin");
  await client.del("/discord");
  const spotifyKeys = await client.keys("/spotify*");
  if (spotifyKeys.length > 0) {
    await client.del(...spotifyKeys);
  }
  return { status: "Cache purged" };
}
async function storeData(endpoint: string, data: RedisStoreGithub | RedisStoreLinkedIn | RedisStoreGithub[] | RedisStoreDiscord | RedisStoreSpotify ) {
  const timestamp = Math.floor(Date.now() / 1000)
  if (Array.isArray(data)) {
    // Store each repo as a separate hash with a unique key
    for (const repo of data) {
      if (repo.timestamp > timestamp - refreshTreshold) {
        const stringifiedData = Object.fromEntries(
          Object.entries(repo).map(([key, value]) =>
            typeof value === "boolean" ? [key, value.toString()] : [key, value]
          )
        );
        await client.set(`/github:${repo.name}`, JSON.stringify(stringifiedData));
        console.log(`Storing data for /github:${repo.name} in Redis with object:\n${JSON.stringify(stringifiedData)}`);
      }
    }
  } else {
    if (data.timestamp > timestamp - refreshTreshold) {
      const stringifiedData = Object.fromEntries(
        Object.entries(data).map(([key, value]) =>
          typeof value === "boolean" ? [key, value.toString()] : [key, value]
        )
      );
      await client.set(`${endpoint}`, JSON.stringify(stringifiedData));
      console.log("Storing data for " + endpoint + " in Redis with object: " + JSON.stringify(stringifiedData));
    }
    else getStoreData(endpoint);
  }
}
async function getStoreData(endpoint: string): Promise<Record<string, unknown> | true> {
  const timestamp = Math.floor(Date.now() / 1000)
  let redisData = await client.hgetall(`${endpoint}`);
  if(redisData && redisData.timestamp && Number(redisData.timestamp) < timestamp - refreshTreshold) {
    redisData = await client.hgetall(`${endpoint}`);
    if (redisData) {
      const parsedRedisData = Object.fromEntries(
        Object.entries(redisData).map(([key, value]) =>
          value === "true" ? [key, true] :
          value === "false" ? [key, false] :
          [key, value]
        )
      );
      console.log(parsedRedisData);
      return parsedRedisData;
    }
  }
  return true;
}
async function getGithubData() {
  // Try to get all cached repos from Redis
  const keys = await client.keys("/github:*");
  const now = Math.floor(Date.now() / 1000);
  let cachedRepos: any[] = [];
  for (const key of keys) {
    const repoData = await client.hgetall(key);
    if (repoData && repoData.timestamp && Number(repoData.timestamp) > now - refreshTreshold) {
      const parsedRepo = Object.fromEntries(
        Object.entries(repoData).map(([k, v]) =>
          v === "true" ? [k, true] :
          v === "false" ? [k, false] :
          [k, v]
        )
      );
      cachedRepos.push(parsedRepo);
    }
  }
  if (cachedRepos.length > 0) {
    return cachedRepos;
  }
  // If cache is stale or missing, fetch new data
  const token = process.env.GITHUB_TOKEN;
  const githubData = await fetch("https://api.github.com/users/lukseh/repos", {
    headers: {
      Authorization: `Bearer ${token}`,
    },
  });
  const data: any[] = await githubData.json();
  const timestamp = Math.floor(Date.now() / 1000);
  const parsedData = data
    .filter((repo: { name: string }) => repo.name !== "Lukseh")
    .map((repo: { name: string, html_url: string, description?: string, homepage?: string, language: string | null, license?: { spdx_id?: string | null }, archived: boolean }) => ({
      name: repo.name,
      url: repo.html_url,
      homepage: repo.homepage && repo.homepage !== '' ? repo.homepage : false,
      language: typeof repo.language === 'string' && repo.language !== '' ? repo.language : 'Unknown',
      license: repo.license && typeof repo.license.spdx_id === 'string' && repo.license.spdx_id !== '' ? repo.license.spdx_id : false,
      archived: repo.archived,
      description: repo.description && typeof repo.description === 'string' && repo.description !== '' ? repo.description: false,
      timestamp: timestamp,
    }));
  await storeData("/github", parsedData);
  return parsedData;
}
async function getlinkedInData() {
  // Try to get cached data from Redis
  const redisData = await client.hgetall("/linkedin");
  const now = Math.floor(Date.now() / 1000);
  if (redisData && redisData.timestamp && Number(redisData.timestamp) > now - refreshTreshold) {
    // Parse booleans and return cached data
    const parsedRedisData = Object.fromEntries(
      Object.entries(redisData).map(([key, value]) =>
        value === "true" ? [key, true] :
        value === "false" ? [key, false] :
        [key, value]
      )
    );
    return parsedRedisData;
  }
  // If cache is stale or missing, fetch new data
  const token = process.env.LINEDIN_TOKEN;
  const linedInData = await fetch("https://api.linkedin.com/v2/userinfo/", {
      headers: {
        Authorization: `Bearer ${token}`,
    },
  });
  const data: { name: string, given_name: string, family_name: string, picture: string } = await linedInData.json();
  const timestamp = Math.floor(Date.now() / 1000);
  const parsedData = {
    full_name: data.name,
    name: data.given_name,
    last_name: data.family_name,
    pfp: data.picture,
    timestamp: timestamp
  };
  await storeData("/linkedin", parsedData);
  return parsedData;
}
async function getDiscordData() {
  // Try to get cached data from Redis
  const redisData = await client.hgetall("/discord");
  const now = Math.floor(Date.now() / 1000);
  if (redisData && redisData.timestamp && Number(redisData.timestamp) > now - refreshTreshold) {
    // Parse booleans and return cached data
    const parsedRedisData = Object.fromEntries(
      Object.entries(redisData).map(([key, value]) =>
        value === "true" ? [key, true] :
        value === "false" ? [key, false] :
        [key, value]
      )
    );
    return parsedRedisData;
  }
  // If cache is stale or missing, fetch new data
  const token = process.env.DISCORD_TOKEN;
  const discordData = await fetch(`https://discord.com/api/v10/users/${process.env.DISCORD_ID}`, {
      headers: {
        Authorization: `Bot ${token}`,
    },
  });
  const data: { username: string, avatar: string, accent_color: number, banner_color: string } = await discordData.json();
  const timestamp = Math.floor(Date.now() / 1000);
  const parsedData = {
    username: data.username,
    avatar: data.avatar,
    accent_color: data.accent_color,
    banner_color: data.banner_color,
    timestamp: timestamp,
  };
  await storeData("/discord", parsedData);
  return parsedData;
}

async function getSkills() {
  return await db.skill.findMany();
}

function privacyPolicy() {
  return ({
    status: "in development"
  })
}

async function getSpotifyAccessToken() {
  const response = await fetch('https://accounts.spotify.com/api/token', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Authorization': 'Basic ' + Buffer.from(
        process.env.SPOTIFY_CLIENT_ID + ':' + process.env.SPOTIFY_CLIENT_SECRET
      ).toString('base64')
    },
    body: new URLSearchParams({
      grant_type: 'refresh_token',
      refresh_token: process.env.SPOTIFY_REFRESH_TOKEN || ''
    })
  });
  const data = await response.json();
  return data.access_token;
}

async function getSpotifyProfile() {
  const accessToken = await getSpotifyAccessToken();
  const response = await fetch('https://api.spotify.com/v1/me', {
    headers: {
      'Authorization': `Bearer ${accessToken}`
    }
  });
  return await response.json();
}
async function getSpotifyData(dataType: string) {
  const now = Math.floor(Date.now() / 1000);
  // Try to get cached data from Redis
  const redisData = await getStoreData(`/spotify:${dataType}`);
  if (redisData && redisData !== true && redisData.timestamp && Number(redisData.timestamp) > now - refreshTreshold) {
    // Parse and return cached data
    try {
      return JSON.parse(redisData.data as string);
    } catch {
      // fallback to refetch if cache is corrupted
    }
  }
  // Fetch fresh data from Spotify
  const accessToken = await getSpotifyAccessToken();
  let endpoint = '';
  const timeRange = 'short_term'; // last 4 weeks
  if (dataType === 'tracks') {
    endpoint = `https://api.spotify.com/v1/me/top/tracks?limit=10&time_range=${timeRange}`;
  } else if (dataType === 'albums') {
    endpoint = `https://api.spotify.com/v1/me/top/tracks?limit=10&time_range=${timeRange}`;
  } else if (dataType === 'artists') {
    endpoint = `https://api.spotify.com/v1/me/top/artists?limit=10&time_range=${timeRange}`;
  } else {
    endpoint = `https://api.spotify.com/v1/me/top/tracks?limit=10&time_range=${timeRange}`;
  }
  const response = await fetch(endpoint, {
    headers: {
      'Authorization': `Bearer ${accessToken}`
    }
  });
  const data = await response.json();
  let result = [];
  if (dataType === 'albums' && data && Array.isArray(data.items)) {
    // Extract unique albums from top tracks
    const albumsMap = new Map();
    data.items.forEach((track: any) => {
      const album = track.album;
      if (album && !albumsMap.has(album.id)) {
        albumsMap.set(album.id, {
          name: album.name,
          artist: album.artists?.map((a: any) => a.name).join(', '),
          url: album.external_urls?.spotify || null,
          image: album.images?.[0]?.url || null,
          release_date: album.release_date || null,
          total_tracks: album.total_tracks || null
        });
      }
    });
    result = Array.from(albumsMap.values());
  } else if (dataType === 'artists' && data && Array.isArray(data.items)) {
    result = data.items.map((artist: any) => ({
      name: artist.name,
      url: artist.external_urls?.spotify || null,
      image: artist.images?.[0]?.url || null,
      genres: artist.genres || [],
      followers: artist.followers?.total || null
    }));
  } else if (dataType === 'tracks' && data && Array.isArray(data.items)) {
    result = data.items.map((track: any) => ({
      name: track.name,
      artist: track.artists?.map((a: any) => a.name).join(', '),
      url: track.external_urls?.spotify || null,
      image: track.album?.images?.[0]?.url || null,
      album: track.album?.name || null
    }));
  }
  // Store result in Redis using storeData
  await storeData(`/spotify:${dataType}`, {
    timestamp: now,
    data: JSON.stringify(result)
  });
  return result;
}

const app = new Elysia()
  .use(cors({
    origin: ["localhost:5173", "api.github.com", "lukseh.dev", "192.168.1.191:5173"]
  }))
  .group("/api", (api) =>
    api
      .get("/", () => "Hello Elysia", {
        summary: "Root endpoint",
        description: "Returns a hello message",
        detail: {
          tags: ["API"]
        }
      })
      .get("/skills", getSkills)
      .get("/discord", async () => await getDiscordData())
      .get("/github", async () => await getGithubData(), {
        summary: "Get GitHub repos",
        detail: {
          tags: ["API"]
        },
        response: {
          200: Type.Array(
            Type.Object({
              name: Type.String(),
              url: Type.String(),
              homepage: Type.Union([Type.String(), Type.Boolean()]),
              language: Type.String(),
              license: Type.Union([Type.String(), Type.Boolean()]),
              archived: Type.Boolean(),
              description: Type.Union([Type.String(), Type.Boolean()]),
            })
          ),
        },
      })
      .get("/linkedin", async () => await getlinkedInData())
      .get("/purge-cache", async ({ headers }) => {
        const authHeader = headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
          return { status: "Unauthorized" };
        }
        const token = authHeader.slice('Bearer '.length);
        if (token.trim() !== JWT_SECRET) {
          return { status: "Unauthorized" };
        }
        // Always return an object
        return await purgeCache();
      }, {
        summary: "Purge Redis cache",
        detail: { tags: ["API"] },
        response: { 200: Type.Object({ status: Type.String() }) }
      })
      .group("/spotify", (spotify) =>
      spotify
      .get("/profile", async () => await getSpotifyProfile())
      .get("/:dataType", async ({ params }) => await getSpotifyData(params.dataType))
      )
      .get("/privacy-policy", () => privacyPolicy())
  )
  .use(swagger({
    path: "/docs",
    documentation: {
      info: {
        title: 'Lukseh.dev portfolio API',
        version: '1.0.0'
      }
    }
  }))
  .listen(3774);

export default app;
