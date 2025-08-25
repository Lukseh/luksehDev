import React, { useEffect, useState } from 'react';
import { Col, Row, Input, Switch } from 'antd';

type Repo = {
    name: string;
    url: string;
    homepage: string | boolean;
    language: string | null;
    license: string | boolean;
    archived?: boolean;
};

function createRepoCards(data: Repo[], search: string, sort: string, showArchived: boolean) {
    if (!data || !Array.isArray(data)) return null;
    let filtered = data.filter(repo => repo.name.toLowerCase().includes(search.toLowerCase()));
    if (!showArchived) filtered = filtered.filter(repo => !repo.archived);
    if (sort === "name") filtered = filtered.sort((a, b) => a.name.localeCompare(b.name));
    if (sort === "language") filtered = filtered.sort((a, b) => (a.language || "").localeCompare(b.language || ""));
    return (
        <Row gutter={[16, 16]}>
            {filtered.map((repo: Repo, idx) => (
                <Col key={repo.name + idx} span={8}>
                    <div className={repo.archived ? "archived-repo" : "active-repo"} style={{ border: '1px solid #eee', padding: 16, borderRadius: 8 }}>
                        <h3>{repo.name}</h3>
                        {/* Only show description if present */}
                        {repo.homepage && typeof repo.homepage === 'string' && repo.homepage !== '' && (
                            <p>Homepage: <a href={repo.homepage} target="_blank" rel="noopener noreferrer">{repo.homepage}</a></p>
                        )}
                        <p>Language: {repo.language ? repo.language : <span style={{color: '#888'}}>Unknown</span>}</p>
                        <p>License: {repo.license && typeof repo.license === 'string' && repo.license !== '' ? repo.license : <span style={{color: '#888'}}>None</span>}</p>
                        <a href={repo.url} target="_blank" rel="noopener noreferrer">
                            View on GitHub
                        </a>
                        {repo.archived && <span style={{color: 'red', fontWeight: 'bold'}}>Archived</span>}
                    </div>
                </Col>
            ))}
        </Row>
    );
}

const GitHubEmbed: React.FC = () => {
    const [data, setData] = useState<Repo[] | null>(null);
    const [search, setSearch] = useState("");
    const [sort, setSort] = useState("name");
    const [showArchived, setShowArchived] = useState(false);

    useEffect(() => {
        async function fetchData() {
            const response = await fetch("http://localhost:3000/api/github");
            const json = await response.json();
            setData(json);
        }
        fetchData();
    }, []);

    return (
        <>
            <div style={{ marginBottom: 16, display: 'flex', gap: 8, alignItems: 'center' }}>
                <Input.Search
                    placeholder="Search repos..."
                    value={search}
                    onChange={e => setSearch(e.target.value)}
                    style={{ flex: 1 }}
                />
                <select value={sort} onChange={e => setSort(e.target.value)} style={{ padding: 8, borderRadius: 4 }}>
                    <option value="name">Sort by Name</option>
                    <option value="language">Sort by Language</option>
                </select>
                <Switch
                    checked={showArchived}
                    onChange={setShowArchived}
                    checkedChildren="Show Archived"
                    unCheckedChildren="Hide Archived"
                    style={{ marginLeft: 8 }}
                />
            </div>
            {createRepoCards(data || [], search, sort, showArchived)}
        </>
    );
}

const GitHub: React.FC = () => {
    return (
        <>
        <GitHubEmbed/>
        </>
    );
};

export default GitHub;