// import React from 'react'
// import { Outlet } from 'react-router-dom';
// import Header from "@/components/header";

// const AppLayout = () => {
//   return (
//       <div>
//       <div className="grid-background"></div>
//       <main className="container mx-auto">
//         <Header />
//         <Outlet />
//       </main>
//       <div className="p-10 text-center bg-gray-800 mt-10">Made by Harpreet</div>
//      </div>
//   )
// }

// export default AppLayout;

import React from 'react';
import { Outlet } from 'react-router-dom';
import Header from "@/components/header.jsx";

const AppLayout = () => {
  return (
    <div className="relative min-h-screen flex flex-col">
      
      {/* Background Grid */}
      <div className="grid-background fixed inset-0 -z-10"></div>

      {/* Header wrapped in container for alignment */}
      <header className="w-full">
        <div className="container mx-auto px-4">
          <Header />
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-1">
        <div className="container mx-auto px-4 py-8">
          <Outlet />
        </div>
      </main>

      {/* Footer */}
      <footer className="p-6 text-center bg-gray-800 text-white">
        Made by Harpreet
      </footer>
    </div>
  );
};

export default AppLayout;
