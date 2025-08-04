'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter_bootstrap.js": "6455e406161a184e870d254ace8ec2c1",
"version.json": "d874c5940e259cb1b207cb4afa0623c9",
"index.html": "077053e9b77d8f27ed4c29f82a1ce3e2",
"/": "077053e9b77d8f27ed4c29f82a1ce3e2",
"main.dart.js": "077686a78b1ae0290141230628ac8c3b",
"flutter.js": "83d881c1dbb6d6bcd6b42e274605b69c",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"manifest.json": "d154ff1b8d404a5df6922b05539ed155",
".git/config": "d6f59f0bc9d73a76c5a884b32cbc428b",
".git/objects/95/9385c9ef203f7957792cfb0d666f4c981c345c": "dca64bb6390a6dddcc1c57f20204efa9",
".git/objects/04/2b2e27ed39ff0f468b68d9aea475acf3574256": "cf2e1bc4eb5dd6e6ec4f26a96d5f8863",
".git/objects/94/402ee9bd1a36b32e2ba7c6026575216f29bbd3": "e014ed6a5eeeb0062e83d21f65a1ce61",
".git/objects/0e/5d5536513c0a2a9fe3fa002fb84073a0c315da": "f859db70e34c4b24dcf45538215d1f78",
".git/objects/33/4c68fcf0fb9fe8c767d02782ff346c60a268a7": "2e9427a322a126d19a48f56f337439ef",
".git/objects/e5/c3c90b0d702c3091fdad69a2bbbb9a3d1fc759": "142398527c48e61376d1dded922a9b16",
".git/objects/c0/78235493b1f026b9ac0cd1cfda07e7a1a653e6": "b1f6966b2391eec92a817a72d5d7c3bf",
".git/objects/fd/86bb7d879cb047ff7b8e03fac292a6ba5b4516": "c6636d16ee304a1f16db226b01357b8b",
".git/objects/ca/c80349f32a699f48b2d0461504db995b6fee14": "64c7d6cddbc77d353f0507d31f78c173",
".git/objects/fb/7757817f5464aa0c6aac24d96945542525042f": "20440bf91c2bcce7c2e6cba310dc7dbe",
".git/objects/pack/pack-cbe31771b73b3f73d436c67c4b2edf4501c122a3.rev": "b5559a8bba712a05806f82bce0f78c73",
".git/objects/pack/pack-cbe31771b73b3f73d436c67c4b2edf4501c122a3.idx": "39d33359d691941a07cc13e7cf876b0a",
".git/objects/pack/pack-cbe31771b73b3f73d436c67c4b2edf4501c122a3.pack": "51c4954330f0731c4e095c16de694a33",
".git/objects/45/517f1fcb6c2c05d86fb604b35f2ae7480778b9": "a92cd41a3dc66e754a564edb3d4ee1c7",
".git/objects/19/eb023650ba83739e0ffc2817fc44f22ca1a771": "e64ca038bcf8c83b207c887bae040a0f",
".git/objects/ef/4f5a7275dc4356b4cd3840922ae4f3f65905fd": "d209a1aeb7e7923761f66cff94f35e5b",
".git/objects/ef/87d836ecd00027cc417f0f595036a9bb977ce6": "d1aa82f3527c24489941baa6246c5128",
".git/objects/c3/210f787ac4b1e1122a7fc698ec883ca8badc30": "128add73479765a53a1dbd7f6ddcfef8",
".git/objects/ea/2f48da82565ec6684d387405bbddf79ea126ce": "3ab267b35e022f1efb50151870096219",
".git/objects/22/0c6558a8facfa6f51d1bac6827b24226d1f6e4": "b57c5599bba9c135929c124eac717a2b",
".git/HEAD": "5ab7a4355e4c959b0c5c008f202f51ec",
".git/logs/HEAD": "4b2af7cc8c15bf616f1aa9f2c4a4518b",
".git/logs/refs/heads/gh-pages": "4b2af7cc8c15bf616f1aa9f2c4a4518b",
".git/logs/refs/remotes/origin/gh-pages": "bc4660752a2dba0e4b6a2d07736fcda7",
".git/logs/refs/remotes/origin/HEAD": "ecec748ecc850d66d81730532219a8eb",
".git/refs/heads/gh-pages": "b10ce0fa7770e2a8e2960fcc60bd725c",
".git/refs/remotes/origin/gh-pages": "b10ce0fa7770e2a8e2960fcc60bd725c",
".git/refs/remotes/origin/HEAD": "b501512a260537c5e52df65d2a034251",
".git/index": "bc1ae3af6ed759c521b1ee05c84e7cb6",
".git/packed-refs": "8387a96601231fa18f29546595774dcf",
".git/COMMIT_EDITMSG": "9086b6bf191d64cbaa7dc5efb7cf1b7c",
".git/FETCH_HEAD": "d41d8cd98f00b204e9800998ecf8427e",
".git/sourcetreeconfig": "c06c96e02e600beedb807cf9a2aba195",
"assets/AssetManifest.json": "491f300584ee76691ac1f791d93d4b8e",
"assets/NOTICES": "240310a4d69d923bf9693648121d09cf",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/AssetManifest.bin.json": "1f17fcf8fa0f6e563df96725fec3c72e",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin": "bda69b2d94259a62c8374769b8373c49",
"assets/fonts/MaterialIcons-Regular.otf": "5cd4f9ffa29a25440de4a28815401fc2",
"assets/assets/logo.png": "304bfa87b70e539ddb9c8e4d6ce0fd03",
"canvaskit/skwasm.js": "ea559890a088fe28b4ddf70e17e60052",
"canvaskit/skwasm.js.symbols": "e72c79950c8a8483d826a7f0560573a1",
"canvaskit/canvaskit.js.symbols": "bdcd3835edf8586b6d6edfce8749fb77",
"canvaskit/skwasm.wasm": "39dd80367a4e71582d234948adc521c0",
"canvaskit/chromium/canvaskit.js.symbols": "b61b5f4673c9698029fa0a746a9ad581",
"canvaskit/chromium/canvaskit.js": "8191e843020c832c9cf8852a4b909d4c",
"canvaskit/chromium/canvaskit.wasm": "f504de372e31c8031018a9ec0a9ef5f0",
"canvaskit/canvaskit.js": "728b2d477d9b8c14593d4f9b82b484f3",
"canvaskit/canvaskit.wasm": "7a3f4ae7d65fc1de6a6e7ddd3224bc93"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
