export const metadata = {
  title: 'Terms of Service | FitForge AI',
  description: 'Terms of Service and End User License Agreement for FitForge AI.',
};

export default function TermsOfService() {
  return (
    <main className="min-h-screen bg-black text-slate-300 py-16 px-6 sm:px-12 lg:px-24">
      <div className="max-w-4xl mx-auto space-y-8">
        <h1 className="text-4xl md:text-5xl font-extrabold text-white mb-2">Terms of Service</h1>
        <p className="text-sm text-[#39FF14] uppercase tracking-widest font-semibold pb-8 border-b border-[#142419]">Effective Date: June 21, 2026</p>

        <section className="space-y-4">
          <p>
            Welcome to FitForge AI. By downloading, accessing, or using our mobile application (the "App"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, do not use the App.
          </p>
        </section>

        <section className="space-y-4">
          <h2 className="text-2xl font-bold text-white">1. Use of the App</h2>
          <p>
            FitForge AI provides fitness and nutrition tracking and AI-generated coaching. You must be at least 18 years old to use the App. You agree to use the App only for lawful purposes and in accordance with these Terms.
          </p>
        </section>

        <section className="space-y-4">
          <h2 className="text-2xl font-bold text-white">2. Medical Disclaimer (Important)</h2>
          <p>
            <strong>FITFORGE AI IS NOT A MEDICAL PROVIDER.</strong> The App provides fitness and nutritional information designed for educational and informational purposes only. You should not rely on this information as a substitute for, nor does it replace, professional medical advice, diagnosis, or treatment. Always consult with a physician or healthcare professional before starting any new fitness program or diet.
          </p>
        </section>

        <section className="space-y-4">
          <h2 className="text-2xl font-bold text-white">3. Subscriptions and Payments</h2>
          <p>
            Certain features of the App are available via a paid subscription. By purchasing a subscription, you agree to the pricing and payment terms presented at the time of purchase. Subscriptions automatically renew unless canceled at least 24 hours before the end of the current billing cycle through your Google Play or Apple App Store account settings.
          </p>
        </section>

        <section className="space-y-4">
          <h2 className="text-2xl font-bold text-white">4. User Accounts and Security</h2>
          <p>
            You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account. You agree to notify us immediately of any unauthorized use of your account.
          </p>
        </section>

        <section className="space-y-4">
          <h2 className="text-2xl font-bold text-white">5. Termination</h2>
          <p>
            We reserve the right to suspend or terminate your access to the App at our sole discretion, without notice, for conduct that we believe violates these Terms or is harmful to other users of the App, us, or third parties, or for any other reason.
          </p>
        </section>

        <section className="space-y-4">
          <h2 className="text-2xl font-bold text-white">6. Limitation of Liability</h2>
          <p>
            To the fullest extent permitted by law, FitForge AI and its developers shall not be liable for any indirect, incidental, special, consequential, or punitive damages, or any loss of profits or revenues, whether incurred directly or indirectly, or any loss of data, use, goodwill, or other intangible losses, resulting from your use of the App.
          </p>
        </section>

        <section className="space-y-4 pb-12">
          <h2 className="text-2xl font-bold text-white">7. Contact Us</h2>
          <p>
            If you have any questions about these Terms, please contact us at: <strong className="text-[#39FF14]">appfitforge@gmail.com</strong>
          </p>
        </section>
      </div>
    </main>
  );
}
