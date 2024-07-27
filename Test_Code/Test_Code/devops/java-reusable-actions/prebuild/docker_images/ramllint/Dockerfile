FROM node

USER node

WORKDIR /home/node

RUN npm install ramllint

ENTRYPOINT ["npx", "--no-install", "ramllint"]