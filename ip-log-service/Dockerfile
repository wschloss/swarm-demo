FROM node:6.11.0

COPY ./package.json ./package.json
RUN npm install

COPY ./server.js ./server.js

EXPOSE 8080

CMD ["node", "server.js"]
