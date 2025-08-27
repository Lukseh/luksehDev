import React, { useEffect, useState } from 'react';

// Minimal VantaEffect type for strict linting
interface VantaEffect {
  destroy?: () => void;
}

declare global {
  interface Window {
    VANTA: {
      NET: (options: Record<string, unknown>) => VantaEffect;
    };
  }
}
interface VantaEffect {
  destroy?: () => void;
  [key: string]: unknown;
}

import { Divider } from 'antd';
import '../styles/cv.css';

interface Skill {
  name: string;
  level: number;
}

const Skills: React.FC = () => {
  const [skills, setSkills] = useState<Skill[]>([]);

  useEffect(() => {
    async function fetchSkills() {
      try {
        const response = await getSkills();
        const data: Skill[] = await response.json();
        setSkills(data);
      } catch (err) {
        console.error('Error fetching skills:', err);
        setSkills([]);
      }
    }
    fetchSkills();
  }, []);

  return (
    <div id="skills-card">
      {skills.map((skill, idx) => (
        <div key={idx} style={{ fontSize: "1.3rem" }}>
          <strong>{skill.name}</strong>: Level {skill.level}
        </div>
      ))}
    </div>
  );
}

async function getSkills() {
  return await fetch(import.meta.env.VITE_API_URL+"/api/skills");
}

async function getLinkedInData() {
  return await fetch(import.meta.env.VITE_API_URL+"/api/linkedin");
}

const CV: React.FC = () => {
  const [linkedInData, setLinkedInData] = useState<{ full_name?: string, pfp?: string } | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setLoading(true);
    async function fetchData() {
      try {
        const response = await getLinkedInData();
        const data = await response.json();
        console.log('LinkedIn API response:', data);
        setLinkedInData(data);
      } catch (err) {
        console.error('Error fetching LinkedIn data:', err);
        setLinkedInData(null);
      } finally {
        setLoading(false);
      }
    }
    fetchData();

    // VANTA.NET initialization
  let vantaEffect: VantaEffect | null = null;
    const cvEl = document.getElementById("cv-background");
    if (cvEl && window.VANTA && typeof window.VANTA.NET === "function") {
      vantaEffect = window.VANTA.NET({
        el: cvEl,
        mouseControls: true,
        touchControls: false,
        gyroControls: false,
        minHeight: 200.00,
        minWidth: 200.00,
        scale: 1.00,
        scaleMobile: 1.00,
        color: 0x4b005f,
        backgroundColor: 0x0,
        points: 15.00,
        maxDistance: 25.00,
        spacing: 13.00
      });
    } else {
      console.warn("VANTA.NET or THREE.js not loaded. VANTA effect will not render.");
    }
    return () => {
      if (vantaEffect && typeof vantaEffect.destroy === "function") {
        vantaEffect.destroy();
      }
    };
  }, []);

  const defaultImg = "https://ui-avatars.com/api/?name=Profile&background=eee&color=888&size=120";

  return (
    <div id="cv-background" style={{ width: "100%", height: "100%", margin: "0",   padding: "0", position: "static" }}>
    <div className='centerContent' id="CV" style={{ backgroundColor: "#00000050", position: "relative", zIndex: 1, overflowY: "scroll" }}>
      {loading ? (
        <div style={{ width: "120px", height: "120px", background: "#eee", borderRadius: "50%", display: "flex", alignItems: "center", justifyContent: "center", position: "relative", zIndex: 2 }}>
          <span style={{ color: "#888" }}>Loading...</span>
        </div>
      ) : linkedInData?.pfp ? (
        <img id="cv-pfp" src={linkedInData.pfp} alt="Profile picture" style={{ width: "10vw", height: "10vw", borderRadius: "50%", position: "relative", zIndex: 2 }} onError={e => { (e.target as HTMLImageElement).src = defaultImg; }} />
      ) : (
        <img id="cv-pfp" src={defaultImg} alt="Default profile" style={{ width: "10vw", height: "10vw", borderRadius: "50%", position: "relative", zIndex: 2 }} />
      )}
      <h1 style={{ fontSize: "3rem", letterSpacing: "1vw", fontWeight: "bolder" }}>
        {linkedInData?.full_name || "No Name"}
      </h1>
      <h1 style={{ fontSize: "1.5rem" }}>Junior Backend Developer</h1>
      <Divider variant="dashed" size="small" style={{ color: "var(--font-color)", borderColor: 'var(--font-color)' }}>Skills</Divider>
      <Skills />
      </div>
    </div>
  );
};
export default CV