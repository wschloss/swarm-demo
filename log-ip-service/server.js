const app = require('express')();

const containerId = process.env.HOSTNAME;

app.get('/*', (req, res) => {
   console.log(`Request from IP: ${ req.ip }`);
   res.send(`Container: ${ containerId} - Your IP is: ${ req.ip }\n`);
});

app.listen(8080, () => { console.log('Server initialized'); });
