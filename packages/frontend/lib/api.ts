export const api = {
  baseURL: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001',
  
  async get(path: string) {
    const response = await fetch(`${this.baseURL}${path}`);
    return response.json();
  },
  
  async post(path: string, data: any) {
    const response = await fetch(`${this.baseURL}${path}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
    return response.json();
  },
}