FROM node:24-bookworm-slim
WORKDIR /app
ADD app.tar.gz /app/
RUN npm ci --omit=dev
ENV NODE_ENV=production PORT=3000 DATABASE_PATH=/data/app.sqlite
EXPOSE 3000
CMD ["npm", "start"]
