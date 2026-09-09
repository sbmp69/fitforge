/** @type {import('next').NextConfig} */
const nextConfig = {
  images: {
    remotePatterns: [
      { protocol: "https", hostname: "*.supabase.co" },
      { protocol: "https", hostname: "images.unsplash.com" },
    ],
  },
  async headers() {
    return [
      {
        source: "/api/:path*",
        headers: [
          { key: "Access-Control-Allow-Credentials", value: "true" },
          { key: "Access-Control-Allow-Origin", value: "*" },
          { key: "Access-Control-Allow-Methods", value: "GET,OPTIONS,PATCH,DELETE,POST,PUT" },
          { key: "Access-Control-Allow-Headers", value: "X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version, Authorization" },
        ],
      },
    ];
  },
  async redirects() {
    return [
      {
        source: '/privacy-policy.html',
        destination: '/privacy-policy',
        permanent: true,
      },
      {
        source: '/terms-of-service.html',
        destination: '/terms-of-service',
        permanent: true,
      },
      {
        source: '/account-deletion.html',
        destination: '/delete-account',
        permanent: true,
      },
      {
        source: '/delete-account.html',
        destination: '/delete-account',
        permanent: true,
      },
      {
        source: '/account-deletion',
        destination: '/delete-account',
        permanent: true,
      },
    ];
  },
};

export default nextConfig;
