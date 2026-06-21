export const metadata = {
  title: 'Privacy Policy | FitForge AI',
  description: 'Privacy Policy for FitForge AI fitness and nutrition application.',
};

export default function PrivacyPolicy() {
  return (
    <main className="min-h-screen bg-black text-slate-300 py-16 px-6 sm:px-12 lg:px-24">
      <div className="max-w-4xl mx-auto space-y-8">
        <h1 className="text-4xl md:text-5xl font-extrabold text-white mb-2">Privacy Policy for FitForge AI</h1>
        <p className="text-sm text-[#39FF14] uppercase tracking-widest font-semibold pb-8 border-b border-[#142419]">Effective Date: June 21, 2026</p>

        <section className="space-y-4">
          <p>
            Welcome to FitForge AI ("we," "our," or "us"). We are committed to protecting your privacy and ensuring that your personal information is handled in a safe and responsible manner. This Privacy Policy outlines how we collect, use, and protect your information when you use our mobile application (the "App").
          </p>
        </section>

        <section className="space-y-4">
          <h2 className="text-2xl font-bold text-white">1. Information We Collect</h2>
          <p>To provide you with personalized AI-driven fitness and nutrition coaching, we collect the following types of information:</p>
          <ul className="list-disc pl-6 space-y-2">
            <li><strong>Account Information:</strong> When you sign up, we collect your email address and basic profile information to create and secure your account.</li>
            <li><strong>Health and Physical Data:</strong> To generate custom meal plans and workouts, we collect your age, gender, weight, height, fitness goals, dietary preferences, and available equipment.</li>
            <li><strong>Progress Photos:</strong> If you choose to use our progress tracking feature, the App requires access to your device's camera and photo library. These photos are stored securely and are only used for your personal tracking dashboard.</li>
            <li><strong>AI Chat Data:</strong> Transcripts of your conversations with the AI Coach are processed to provide context-aware fitness advice and improve your coaching experience.</li>
            <li><strong>Usage and Device Data:</strong> We collect crash logs, device identifiers, and usage metrics to monitor app performance and fix bugs.</li>
            <li><strong>Payment Information:</strong> If you subscribe to our Pro or Trainer tiers, payments are processed securely via our third-party payment providers (e.g., Google Play Billing, Apple App Store). We do not store your direct credit card numbers on our servers.</li>
          </ul>
        </section>

        <section className="space-y-4">
          <h2 className="text-2xl font-bold text-white">2. How We Use Your Information</h2>
          <p>We use the data we collect solely to provide and improve the FitForge AI service:</p>
          <ul className="list-disc pl-6 space-y-2">
            <li>To generate highly-personalized workout routines and macro-calculated meal plans via our AI engines.</li>
            <li>To send you push notifications (e.g., daily reminders to log your progress or hydration).</li>
            <li>To analyze app performance and fix technical issues.</li>
            <li>To maintain the security and integrity of your account.</li>
          </ul>
        </section>

        <section className="space-y-4">
          <h2 className="text-2xl font-bold text-white">3. Push Notifications</h2>
          <p>
            The App uses push notifications to send you fitness reminders (such as your 5 PM progress logging reminder). You can opt-out of these notifications at any time through your device's system settings or the App's Profile screen.
          </p>
        </section>

        <section className="space-y-4">
          <h2 className="text-2xl font-bold text-white">4. Data Sharing and Disclosure</h2>
          <p>We <strong>do not</strong> sell your personal or health data to third parties. We may share your data only in the following circumstances:</p>
          <ul className="list-disc pl-6 space-y-2">
            <li><strong>Service Providers:</strong> We may share data with secure third-party infrastructure providers (such as cloud hosting and our AI language model providers) strictly for the purpose of operating the App. Data sent to AI models is anonymized where possible.</li>
            <li><strong>Legal Requirements:</strong> If required by law, subpoena, or other legal processes.</li>
          </ul>
        </section>

        <section className="space-y-4">
          <h2 className="text-2xl font-bold text-white">5. Data Security and Retention</h2>
          <p>
            We implement industry-standard encryption and security protocols to protect your personal and health data from unauthorized access. We retain your data only for as long as your account is active or as needed to provide you the services. You may delete your account and all associated data at any time via the settings menu in the App.
          </p>
        </section>

        <section className="space-y-4">
          <h2 className="text-2xl font-bold text-white">6. Your Rights</h2>
          <p>
            Depending on your location, you may have the right to request access to, correction of, or deletion of your personal data. You can exercise these rights by contacting our support team.
          </p>
        </section>

        <section className="space-y-4">
          <h2 className="text-2xl font-bold text-white">7. Changes to This Privacy Policy</h2>
          <p>
            We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy within the App and updating the "Effective Date" at the top.
          </p>
        </section>

        <section className="space-y-4 pb-12">
          <h2 className="text-2xl font-bold text-white">8. Contact Us</h2>
          <p>
            If you have any questions or suggestions about our Privacy Policy, do not hesitate to contact us at: <strong className="text-[#39FF14]">appfitforge@gmail.com</strong>
          </p>
        </section>
      </div>
    </main>
  );
}
