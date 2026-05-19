/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  // Served behind nginx at /vAdmin/ — see /etc/nginx/conf.d/app.conf
  basePath: '/vAdmin',
  // nginx location /vAdmin/ requires the trailing slash; keep it canonical
  trailingSlash: true,
  experimental: {
    serverActions: { allowedOrigins: ['localhost:4100', 'localhost:4101', '172.86.121.43'] },
  },
  // Proxy bearer-token traffic through Next.js so admin-only routes can be
  // gated by middleware. The backend lives on a separate origin.
  async rewrites() {
    return [
      {
        source: '/api/backend/:path*',
        destination: `${process.env.BACKEND_BASE_URL ?? 'http://localhost:3000'}/api/:path*`,
      },
    ];
  },
};

export default nextConfig;
