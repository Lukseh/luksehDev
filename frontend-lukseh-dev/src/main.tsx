import { StrictMode } from 'react';
import React from 'react';
import { createRoot } from 'react-dom/client';
import './styles/index.css';
import { createBrowserRouter, RouterProvider, Outlet } from 'react-router-dom';
import { Layout } from "antd";

// Component import
import NavBar from './components/nav';

// Pages import
import Index from './pages/index';
import GitHub from './pages/github';
import CV from './pages/cv';

const router = createBrowserRouter([
  {
    path: '/',
    element: (
      <Layout>
        <NavBar />
        <main style={{ padding: "2vw" }}>
          <React.Suspense fallback={<div>Loading...</div>}>
            <Outlet />
          </React.Suspense>
        </main>
      </Layout>
    ),
    children: [
      {
        index: true,
        element: <Index />,
      },
    ]
  },
    {
    path: '/github',
    element: (
      <Layout>
        <NavBar />
        <main style={{ padding: "2vw" }}>
          <React.Suspense fallback={<div>Loading...</div>}>
            <Outlet />
          </React.Suspense>
        </main>
      </Layout>
    ),
    children: [
      {
        index: true,
        element: <GitHub/>
      }
    ],
  },
  {
    path: '/cv',
    element: (
      <Layout>
        <NavBar />
        <main style={{ padding: "2vw" }}>
          <React.Suspense fallback={<div>Loading...</div>}>
            <Outlet />
          </React.Suspense>
        </main>
      </Layout>
    ),
    children: [
      {
        index: true,
        element: <CV/>
      }
    ],
  }
])
createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <RouterProvider router={router} />
  </StrictMode>,
)
