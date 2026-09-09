
import Link from 'next/link';
import { Button } from '@/components/ui/button';

export default function Home() {
  return (
    <main className="min-h-screen bg-gradient-to-b from-blue-50 to-white dark:from-gray-900 dark:to-gray-950">
      <div className="container mx-auto px-4 py-16">
        <div className="text-center mb-12">
          <h1 className="text-5xl font-bold mb-4">Decentralized Task Marketplace</h1>
          <p className="text-xl text-gray-600 dark:text-gray-300 mb-8">
            Connect AI Agents and Human Workers for automated task execution
          </p>
          <div className="flex gap-4 justify-center">
            <Button asChild size="lg"><Link href="/marketplace">Explore Tasks</Link></Button>
            <Button asChild size="lg" variant="outline"><Link href="/agents">Browse Agents</Link></Button>
          </div>
        </div>
      </div>
    </main>
  );
}
