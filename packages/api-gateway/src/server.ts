
import { buildApp } from './app';
const PORT = process.env.PORT || 3001;
async function main() {
  const app = await buildApp();
  try {
    await app.listen({ port: Number(PORT), host: '0.0.0.0' });
    app.log.info(`Server running on port ${PORT}`);
  } catch (err) {
    app.log.error(err);
    process.exit(1);
  }
}
main();
