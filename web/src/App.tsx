import { ApolloProvider } from '@apollo/client/react';
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { Toaster } from 'react-hot-toast';
import { apolloClient } from './api/apollo-client';
import { HotelsPage } from './pages/HotelsPage';
import { HotelDetailPage } from './pages/HotelDetailPage';
import { RoomDetailPage } from './pages/RoomDetailPage';

function AppLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-white border-b border-gray-200">
        <div className="max-w-4xl mx-auto px-4 py-4">
          <h1 className="text-xl font-bold text-gray-900">
            <a href="/" className="hover:text-blue-600 transition-colors">
              Mini Booking
            </a>
          </h1>
        </div>
      </header>
      <main className="max-w-4xl mx-auto px-4 py-6">
        {children}
      </main>
    </div>
  );
}

function App() {
  return (
    <ApolloProvider client={apolloClient}>
      <Toaster position="top-right" />
      <BrowserRouter>
        <AppLayout>
          <Routes>
            <Route path="/" element={<HotelsPage />} />
            <Route path="/hotels/:hotelId" element={<HotelDetailPage />} />
            <Route path="/hotels/:hotelId/rooms/:roomId" element={<RoomDetailPage />} />
            <Route path="*" element={
              <div className="text-center py-12">
                <h2 className="text-2xl font-bold text-gray-900 mb-2">404</h2>
                <p className="text-gray-500">Page not found</p>
                <a href="/" className="text-blue-600 hover:underline mt-4 inline-block">
                  Back to hotels
                </a>
              </div>
            } />
          </Routes>
        </AppLayout>
      </BrowserRouter>
    </ApolloProvider>
  );
}

export default App;
