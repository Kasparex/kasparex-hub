export function Footer() {
  return (
    <footer className="bg-gray-50 py-8">
      <div className="container mx-auto px-4">
        <div className="text-center text-gray-600">
          <p className="mb-2">© {new Date().getFullYear()} Kasparex Hub</p>
          <p className="text-sm">All rights reserved</p>
        </div>
      </div>
    </footer>
  );
}

