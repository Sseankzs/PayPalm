// merchant-app.js (Express-based mock web app)
const express = require('express');
const axios = require('axios');
const path = require('path');
const app = express();
app.use(express.json());
app.use(express.static('public'));

const PI_BASE_URL = 'http://172.20.10.2:5001'; // Replace with actual Pi IP

app.post('/checkout', async (req, res) => {
  const { transaction_id, amount } = req.body;
  try {
    const response = await axios.post(`${PI_BASE_URL}/authenticate`, {
      transaction_id,
      amount
    });
    res.json(response.data);
  } catch (err) {
    res.status(500).json({ error: 'Failed to authenticate via Pi' });
  }
});

app.post('/register', async (req, res) => {
  try {
    const response = await axios.post(`${PI_BASE_URL}/register`, {});
    res.json(response.data);
  } catch (err) {
    res.status(500).json({ error: 'Failed to initiate registration via Pi' });
  }
});

app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.listen(3000, () => console.log('Merchant app running on port 3000'));