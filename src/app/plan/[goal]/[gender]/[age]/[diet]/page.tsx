import { Metadata } from 'next';
import Link from 'next/link';

// Define the expected dynamic parameters
interface PlanProps {
  params: {
    goal: string;
    gender: string;
    age: string;
    diet: string;
  };
}

// Utility to format slug strings to Title Case (e.g., "lose-weight" -> "Lose Weight")
function formatSlug(slug: string) {
  if (!slug) return '';
  return slug
    .split('-')
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ');
}

// 1. Generate dynamic SEO Metadata
export async function generateMetadata({ params }: PlanProps): Promise<Metadata> {
  const goal = formatSlug(params.goal);
  const gender = formatSlug(params.gender);
  const age = formatSlug(params.age);
  const diet = formatSlug(params.diet);

  const title = `Customized ${diet} Diet & Workout Plan for ${gender} ${age} to ${goal} | FitForge AI`;
  const description = `Stop guessing. Get an AI-generated ${diet} fitness regimen tailored exactly for ${gender} ${age} looking to ${goal}. Download FitForge AI to generate your plan.`;

  return {
    title,
    description,
    openGraph: {
      title,
      description,
      type: 'website',
    },
  };
}

// 2. The Main Page Component
export default function ProgrammaticSEOPage({ params }: PlanProps) {
  const goal = formatSlug(params.goal);
  const gender = formatSlug(params.gender);
  const age = formatSlug(params.age);
  const diet = formatSlug(params.diet);

  // 3. Schema.org JSON-LD structured data for Google Rich Snippets
  const jsonLd = {
    '@context': 'https://schema.org',
    '@type': 'SoftwareApplication',
    name: 'FitForge AI',
    operatingSystem: 'ANDROID, IOS',
    applicationCategory: 'HealthAndFitnessApplication',
    offers: {
      '@type': 'Offer',
      price: '0',
      priceCurrency: 'USD',
    },
    description: `AI-powered ${diet} workout and meal plans tailored for ${gender} ${age} wanting to ${goal}.`,
  };

  const faqLd = {
    '@context': 'https://schema.org',
    '@type': 'FAQPage',
    mainEntity: [
      {
        '@type': 'Question',
        name: `How do ${gender.toLowerCase()} ${age.toLowerCase()} successfully ${goal.toLowerCase()}?`,
        acceptedAnswer: {
          '@type': 'Answer',
          text: `The most effective way for ${gender.toLowerCase()} ${age.toLowerCase()} to ${goal.toLowerCase()} is by following a structured ${diet.toLowerCase()} meal plan paired with targeted progressive overload. FitForge AI generates this automatically based on your specific body metrics.`,
        },
      },
    ],
  };

  return (
    <main className="min-h-screen bg-black text-slate-50 selection:bg-[#39FF14] selection:text-black flex flex-col items-center justify-center p-6">
      {/* Inject Structured Data */}
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }} />
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(faqLd) }} />

      <div className="max-w-4xl w-full text-center space-y-8 animate-in fade-in slide-in-from-bottom-8 duration-1000">
        <div className="inline-block px-4 py-1.5 rounded-full border border-[#39FF14]/30 bg-[#39FF14]/10 text-[#39FF14] text-sm font-semibold mb-4 tracking-wide">
          AI GENERATED PLAN READY
        </div>
        
        <h1 className="text-5xl md:text-7xl font-extrabold tracking-tight">
          The Ultimate <span className="text-[#39FF14]">{diet}</span> Plan to <br/>
          <span className="font-serif italic font-light text-slate-300">{goal}</span>
        </h1>
        
        <p className="text-xl text-slate-400 max-w-2xl mx-auto leading-relaxed">
          We have customized a highly-specific workout routine and nutrition protocol exclusively designed for <strong className="text-white">{gender} {age}</strong>.
        </p>

        <div className="bg-[#0A110C] border border-[#142419] rounded-3xl p-8 max-w-2xl mx-auto shadow-2xl shadow-[#39FF14]/5 my-12">
          <h3 className="text-2xl font-bold mb-6 text-left border-b border-[#142419] pb-4">What's included in your plan:</h3>
          <ul className="text-left space-y-4 text-slate-300">
            <li className="flex items-center gap-3">
              <span className="flex items-center justify-center w-8 h-8 rounded-full bg-[#39FF14]/20 text-[#39FF14]">✓</span>
              Day-by-day {goal.toLowerCase()} workout circuits.
            </li>
            <li className="flex items-center gap-3">
              <span className="flex items-center justify-center w-8 h-8 rounded-full bg-[#39FF14]/20 text-[#39FF14]">✓</span>
              Precise macro-calculated {diet.toLowerCase()} meal plans.
            </li>
            <li className="flex items-center gap-3">
              <span className="flex items-center justify-center w-8 h-8 rounded-full bg-[#39FF14]/20 text-[#39FF14]">✓</span>
              Automated grocery list generation.
            </li>
            <li className="flex items-center gap-3">
              <span className="flex items-center justify-center w-8 h-8 rounded-full bg-[#39FF14]/20 text-[#39FF14]">✓</span>
              24/7 access to your personal AI Coach.
            </li>
          </ul>
        </div>

        <div className="space-y-6">
          <p className="text-slate-400 text-sm">To access your personalized protocol, install the FitForge app below.</p>
          <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
            <Link 
              href="https://play.google.com/store" 
              className="px-8 py-4 bg-[#39FF14] text-black font-bold rounded-full text-lg hover:bg-[#65D84C] transition-colors w-full sm:w-auto shadow-lg shadow-[#39FF14]/20"
            >
              Get it on Google Play
            </Link>
            <Link 
              href="https://apps.apple.com" 
              className="px-8 py-4 bg-[#0A110C] border border-[#39FF14]/50 text-white font-bold rounded-full text-lg hover:bg-[#142419] transition-colors w-full sm:w-auto"
            >
              Download on the App Store
            </Link>
          </div>
        </div>
      </div>
    </main>
  );
}
