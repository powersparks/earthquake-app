export async function POST(request) {
  try {
    const { searchParams } = new URL(request.url);
    const days = searchParams.get('days') || 1;
    const backendUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';
    
    const res = await fetch(`${backendUrl}/refresh?days=${days}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
    });
    
    if (!res.ok) {
      throw new Error(`Backend returned ${res.status}`);
    }
    
    const data = await res.json();
    return Response.json(data);
  } catch (error) {
    console.error('Error refreshing earthquakes:', error);
    return Response.json(
      { error: error.message },
      { status: 500 }
    );
  }
}
