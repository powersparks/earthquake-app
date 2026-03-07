export async function GET(request) {
  try {
    const { searchParams } = new URL(request.url);
    const backendUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';
    
    const params = new URLSearchParams();
    searchParams.forEach((value, key) => {
      params.append(key, value);
    });
    
    const res = await fetch(`${backendUrl}/earthquakes?${params}`, {
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
    console.error('Error fetching earthquakes:', error);
    return Response.json(
      { error: error.message },
      { status: 500 }
    );
  }
}
