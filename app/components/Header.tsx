export function Header() {
  return (
    <header className="sticky top-0 z-50 bg-white shadow-sm">
      <div className="container mx-auto px-4 py-4">
        <div className="flex items-center justify-between">
          {/* Left side: Logo + Title */}
          <div className="flex items-center gap-3">
            <img
              src="/img/logos/kasparex.png"
              alt="Kasparex Logo"
              className="h-8 w-8 object-contain"
            />
            <h1 className="text-xl font-bold text-gray-900">Kasparex Hub</h1>
          </div>

          {/* Right side: Button */}
          <button className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-blue-700">
            Get Started
          </button>
        </div>
      </div>
    </header>
  );
}

