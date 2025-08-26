import React from 'react';
import { QRCode } from 'antd';

const CVHeader: React.FC = () => {
    return (
        <>
            <QRCode
                style= {{ backgroundColor: 'white' }}
                errorLevel="H"
                value="https://www.linkedin.com/in/lukseh74"
                icon="https://lukseh.dev/android-chrome-512x512.png"
            />
        </>
    );
}

const CV: React.FC = () => {
    return (
    <div className='centerContent'>
        <CVHeader/>
    </div>
    );
};

export default CV