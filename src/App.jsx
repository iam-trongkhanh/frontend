import React, { useEffect, useState } from 'react';

const apiBase = import.meta.env.VITE_API_URL || 'http://localhost:3001';

export default function App() {
  const [items, setItems] = useState([]);
  const [form, setForm] = useState({ title: '', description: '' });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const fetchItems = async () => {
    setError('');
    try {
      const res = await fetch(`${apiBase}/api/items`);
      if (!res.ok) throw new Error('Failed to fetch items');
      const data = await res.json();
      setItems(data);
    } catch (err) {
      setError(err.message);
    }
  };

  useEffect(() => {
    fetchItems();
  }, []);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!form.title.trim()) return;
    setLoading(true);
    setError('');
    try {
      const res = await fetch(`${apiBase}/api/items`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(form)
      });
      if (!res.ok) throw new Error('Failed to create item');
      setForm({ title: '', description: '' });
      fetchItems();
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <main className="page">
      <header>
        <h1>MERN Starter</h1>
        <p>Frontend: React + Vite · Backend: Express + MongoDB</p>
      </header>

      <section className="card">
        <h2>Add Item</h2>
        <form onSubmit={handleSubmit}>
          <input
            type="text"
            placeholder="Title"
            value={form.title}
            onChange={(e) => setForm({ ...form, title: e.target.value })}
            required
          />
          <input
            type="text"
            placeholder="Description"
            value={form.description}
            onChange={(e) => setForm({ ...form, description: e.target.value })}
          />
          <button type="submit" disabled={loading}>
            {loading ? 'Saving...' : 'Create'}
          </button>
        </form>
        {error && <p className="error">{error}</p>}
      </section>

      <section className="card">
        <h2>Items</h2>
        {items.length === 0 && <p>No items yet.</p>}
        <ul>
          {items.map((item) => (
            <li key={item._id || item.title}>
              <strong>{item.title}</strong>
              {item.description ? <span> — {item.description}</span> : null}
            </li>
          ))}
        </ul>
      </section>
    </main>
  );
}

