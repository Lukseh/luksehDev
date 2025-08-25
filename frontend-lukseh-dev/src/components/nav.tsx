import { Layout, Menu } from 'antd';
import { HomeOutlined, GithubOutlined } from '@ant-design/icons';
import type { MenuProps } from 'antd';
import { useNavigate } from 'react-router-dom';
import React, { useState } from 'react';

const { Header } = Layout;

type MenuItem = Required<MenuProps>['items'][number];

const items: MenuItem[] = [
    {
        key: '/',
        icon: <HomeOutlined style={{ fontSize: '1.5rem' }}/>,
        label: 'Home',
    },
    {
        key: '/github',
        icon: <GithubOutlined style={{ fontSize: '1.5rem' }}/>,
        label: 'GitHub',
    }
];

import { useLocation } from 'react-router-dom';

function NavBar() {
    const location = useLocation();
    const [current, setCurrent] = useState<string>(location.pathname);
    const navigate = useNavigate();

    // Update selected key when location changes
    React.useEffect(() => {
        setCurrent(location.pathname);
    }, [location.pathname]);

    const onClick: MenuProps['onClick'] = (e) => {
        setCurrent(e.key);
        navigate(e.key);
    };

    return (
        <Header
            style={{
                position: 'sticky',
                top: 0,
                zIndex: 1,
                width: '100%',
                height: "7vh",
                display: 'flex',
                alignItems: 'center',
                backgroundColor: "var(--alt-color)"
            }}
        >
            <Menu
                theme="dark"
                mode="horizontal"
                items={items}
                style={{ flex: 1, minWidth: 0, fontSize: "1.5rem", backgroundColor: "var(--alt-color)" }}
                onClick={onClick}
                selectedKeys={[current]}
            />
        </Header>
    );
}

export default NavBar;