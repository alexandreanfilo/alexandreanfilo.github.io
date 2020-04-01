var socket;

self.addEventListener('message', function (e) {
   var data = e.data;

   switch (data.action) {
      case 1:
         self.postMessage({ action: 1, response: 2 });

         ws(data.addr);

         break;
      case 2:
         socket.send(JSON.stringify(data.request));

         break;
      case 3:
         socket.close();

         close();

         break;
   }
}, false);

function ws(addr) {
   var addr = addr;

   socket = new WebSocket(addr);

   socket.onerror = function (e) {
      console.error(e);

      self.postMessage({ action: 0, response: 0, msg: e.message });
   }

   socket.onopen = function () {
      self.postMessage({ action: 1, response: 1 });
   }

   socket.onmessage = function (event) {
      try {
         var msg = JSON.parse(event.data);

         self.postMessage(msg);
      } catch (err) {
         console.error(err);

         self.postMessage({ action: 0, response: 0, msg: err.message });
      }
   }

   socket.onclose = function (event) {
      if (event.code !== 3001) {
         self.postMessage({ action: 1, response: 0 });
      } else {
         self.postMessage({ action: 3, response: 1 });
      }
   }
}