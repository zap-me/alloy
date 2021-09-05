var lastNonce = 0;

int nextNonce() {
  var nonce = DateTime.now().toUtc().millisecondsSinceEpoch;
  if (nonce <= lastNonce) nonce = lastNonce + 1;
  lastNonce = nonce;
  return nonce;
}