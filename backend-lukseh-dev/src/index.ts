import { Elysia } from "elysia";
import cors from '@elysiajs/cors'
import { swagger } from '@elysiajs/swagger'
import { Type } from '@sinclair/typebox';

async function getGithubData() {
  const token = process.env.GITHUB_TOKEN;
  const githubData = await fetch("https://api.github.com/users/lukseh/repos", {
    headers: {
      Authorization: `Bearer ${token}`,
    },
  });
  const data: any[] = await githubData.json();
  const parsedData = data
    .filter((repo: { name: string }) => repo.name !== "Lukseh")
    .map((repo: { name: string, html_url: string, homepage?: string, language: string | null, license?: { spdx_id?: string | null }, archived: boolean }) => ({
      name: repo.name,
      url: repo.html_url,
      homepage: repo.homepage && repo.homepage !== '' ? repo.homepage : false,
      language: typeof repo.language === 'string' && repo.language !== '' ? repo.language : 'Unknown',
      license: repo.license && typeof repo.license.spdx_id === 'string' && repo.license.spdx_id !== '' ? repo.license.spdx_id : false,
      archived: repo.archived
    }));
  return parsedData;
}

const app = new Elysia()
  .use(cors({
    origin: ["localhost:5173", "api.github.com"]
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
      .get("/github", getGithubData, {
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
            })
          ),
        },
      })
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
  .listen(3000);

export default app;
