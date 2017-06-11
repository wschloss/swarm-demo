const app = require('express')();

const containerId = process.env.HOSTNAME;

app.get('/*', (req, res) => {
   res.send(`Container: ${ containerId }\n`);
});

app.listen(8080, () => { console.log('Server initialized'); });
