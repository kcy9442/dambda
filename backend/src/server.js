const express = require('express');
const cors = require('cors');
const config = require('./config');
const authRoutes = require('./routes/auth');

const app = express();
app.use(cors());
app.use(express.json());

// ALB 타겟그룹 헬스체크가 무인증으로 이 경로를 침
app.get('/', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

app.use('/auth', authRoutes);

app.listen(config.port, () => {
  console.log(`dambda-backend listening on port ${config.port}`);
});
