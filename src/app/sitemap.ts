import { MetadataRoute } from 'next';

const DOMAIN = 'https://fitforge.ai';

// We define the core arrays of our SEO strategy
const goals = ['lose-weight', 'build-muscle', 'body-recomposition', 'get-shredded'];
const genders = ['men', 'women'];
const ages = ['under-30', 'over-30', 'over-40', 'over-50'];
const diets = ['vegetarian', 'vegan', 'keto', 'paleo', 'indian-diet', 'standard'];

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const sitemapEntries: MetadataRoute.Sitemap = [
    {
      url: `${DOMAIN}/`,
      lastModified: new Date(),
      changeFrequency: 'weekly',
      priority: 1.0,
    },
  ];

  // Recursively generate all permutations for the pSEO engine
  // This will generate 4 * 2 * 4 * 6 = 192 highly specific landing pages instantly
  // In a real-world scenario, we could expand these arrays to generate 10,000+ pages
  for (const goal of goals) {
    for (const gender of genders) {
      for (const age of ages) {
        for (const diet of diets) {
          sitemapEntries.push({
            url: `${DOMAIN}/plan/${goal}/${gender}/${age}/${diet}`,
            lastModified: new Date(),
            changeFrequency: 'monthly',
            priority: 0.8,
          });
        }
      }
    }
  }

  return sitemapEntries;
}
