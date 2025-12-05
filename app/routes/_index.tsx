import { Header } from "~/components/Header";
import { FeatureCard } from "~/components/FeatureCard";
import { Footer } from "~/components/Footer";

export default function Index() {
  const features = [
    {
      icon: "🚀",
      title: "dApps",
      description: "Discover and use decentralized applications",
    },
    {
      icon: "🪙",
      title: "Tokens",
      description: "Explore KRC-20 tokens and assets",
    },
    {
      icon: "⚡",
      title: "Nodes",
      description: "Manage your Krex Nodes",
    },
  ];

  return (
    <div className="flex min-h-screen flex-col">
      <Header />
      <main className="flex-1">
        <div className="container mx-auto px-4 py-12">
          <div className="mb-12 text-center">
            <h2 className="mb-4 text-4xl font-bold text-gray-900">
              Welcome to Kasparex Hub
            </h2>
            <p className="mx-auto max-w-2xl text-lg text-gray-600">
              Your gateway to the Kaspa ecosystem. Discover dApps, explore
              tokens, and manage your nodes all in one place.
            </p>
          </div>

          <div className="grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-3">
            {features.map((feature) => (
              <FeatureCard
                key={feature.title}
                icon={feature.icon}
                title={feature.title}
                description={feature.description}
              />
            ))}
          </div>
        </div>
      </main>
      <Footer />
    </div>
  );
}

