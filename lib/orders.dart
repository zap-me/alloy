import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

import 'package:zapdart/utils.dart';
import 'package:zapdart/widgets.dart';
import 'package:zapdart/colors.dart';

import 'beryllium.dart';
import 'websocket.dart';
import 'utils.dart';
import 'assets.dart';

class OrderScreen extends StatefulWidget {
  final BeBrokerOrder order;
  final Websocket websocket;

  OrderScreen(this.order, this.websocket);

  @override
  State<OrderScreen> createState() => _OrderScreenState(order);
}

class _OrderScreenState extends State<OrderScreen> {
  BeBrokerOrder _order;
  var processOrderUpdates = true;
  var _testnet = false;

  _OrderScreenState(this._order);

  @override
  void initState() {
    super.initState();
    widget.websocket.wsEvent.subscribe(_websocketEvent);
  }

  @override
  void dispose() {
    super.dispose();
    widget.websocket.wsEvent.unsubscribe(_websocketEvent);
  }

  void _websocketEvent(WsEventArgs? args) {
    if (!processOrderUpdates) return;
    if (args == null) return;
    if (args.event == WebsocketEvent.brokerOrderUpdate) {
      var newOrder = BeBrokerOrder.parse(jsonDecode(args.msg));
      if (_order.token == newOrder.token) {
        setState(() => _order = newOrder);
        flushbarMsg(context,
            'broker order updated ${newOrder.token} - ${describeEnum(newOrder.status).toUpperCase()}');
      }
    }
  }

  void _addrLaunch() {
    var url =
        addressBlockExplorer(_order.baseAsset, _testnet, _order.recipient);
    if (url == null) return;
    urlLaunch(url);
  }

  Future<void> _accept() async {
    processOrderUpdates = false;
    showAlertDialog(context, 'accepting..');
    var res = await beOrderAccept(_order.token);
    Navigator.pop(context);
    processOrderUpdates = true;
    if (res.error.type == ErrorType.None)
      setState(() => _order = res.order);
    else
      alert(context, 'error', 'failed to accept order (${res.error.msg})');
  }

  Future<void> _update() async {
    processOrderUpdates = false;
    showAlertDialog(context, 'updating..');
    var res = await beOrderStatus(_order.token);
    Navigator.pop(context);
    processOrderUpdates = true;
    if (res.error.type == ErrorType.None)
      setState(() => _order = res.order);
    else
      alert(
          context, 'error', 'failed to update order status (${res.error.msg})');
  }

  @override
  Widget build(BuildContext context) {
    var baseAmount = assetFormat(_order.baseAsset, _order.baseAmount);
    var quoteAmount = assetFormat(_order.quoteAsset, _order.quoteAmount);
    return Scaffold(
        appBar: AppBar(
          title: Text('Order ${_order.token}'),
          actions: [assetLogo(_order.baseAsset, margin: EdgeInsets.all(10))],
        ),
        body: ListView(children: [
          ListTile(
              title: Text('Market'),
              subtitle: Text(
                  '${_order.market} - ${marketSideNice(_order.side)} $baseAmount ${_order.baseAsset}')),
          ListTile(
              title: Text('Price'),
              subtitle: Text(
                  '$baseAmount ${_order.baseAsset} for $quoteAmount ${_order.quoteAsset}')),
          ListTile(title: Text('Date'), subtitle: Text('${_order.date}')),
          _order.status == BeOrderStatus.created ||
                  _order.status == BeOrderStatus.ready
              ? ListTile(
                  title: Text('Expiry'), subtitle: Text('${_order.expiry}'))
              : SizedBox(),
          ListTile(
              title: Text('Recipient'),
              subtitle: Text('${_order.recipient}'),
              onTap: _addrLaunch),
          ListTile(
              title: Text('Status'),
              subtitle: Text('${describeEnum(_order.status).toUpperCase()}')),
          _order.paymentUrl != null && _order.status == BeOrderStatus.ready
              ? ListTile(
                  title: Text('Payment URL'),
                  subtitle: Text('${_order.paymentUrl}'),
                  onTap: () => urlLaunch(_order.paymentUrl))
              : SizedBox(),
          _order.status == BeOrderStatus.created
              ? ListTile(
                  title:
                      raisedButton(onPressed: _accept, child: Text('Accept')))
              : SizedBox(),
          _order.status != BeOrderStatus.expired &&
                  _order.status != BeOrderStatus.cancelled &&
                  _order.status != BeOrderStatus.completed
              ? ListTile(
                  title:
                      raisedButton(onPressed: _update, child: Text('Update')))
              : SizedBox(),
        ]));
  }
}

class OrdersScreen extends StatefulWidget {
  final List<BeBrokerOrder> orders;
  final Websocket websocket;

  OrdersScreen(this.orders, this.websocket);

  @override
  State<OrdersScreen> createState() => _OrdersScreenState(orders);
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<BeBrokerOrder> _orders;
  _OrdersScreenState(this._orders);
  int _currentPage = 0;
  int _ordersPerPage = 7;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    widget.websocket.wsEvent.subscribe(_websocketEvent);
    _totalPages = (_orders.length / _ordersPerPage).ceil();
    print('_totalPages is ${_totalPages}');
  }

  @override
  void dispose() {
    super.dispose();
    widget.websocket.wsEvent.unsubscribe(_websocketEvent);
  }

  void _websocketEvent(WsEventArgs? args) {
    if (args == null) return;
    if (args.event == WebsocketEvent.brokerOrderNew) {
      var newOrder = BeBrokerOrder.parse(jsonDecode(args.msg));
      _orders.insert(0, newOrder);
      setState(() => _orders = _orders);
      flushbarMsg(context,
          'broker order created ${newOrder.token} - ${describeEnum(newOrder.status).toUpperCase()}');
    }
    if (args.event == WebsocketEvent.brokerOrderUpdate) {
      var newOrders = <BeBrokerOrder>[];
      var newOrder = BeBrokerOrder.parse(jsonDecode(args.msg));
      for (var order in _orders)
        if (order.token == newOrder.token)
          newOrders.add(newOrder);
        else
          newOrders.add(order);
      setState(() => _orders = newOrders);
      flushbarMsg(context,
          'broker order updated ${newOrder.token} - ${describeEnum(newOrder.status).toUpperCase()}');
    }
  }

  Future<void> _orderTap(BeBrokerOrder order) async {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => OrderScreen(order, widget.websocket)));
  }

  Widget _listItem(BuildContext context, int n) {
    int actualizedNumber =
        _currentPage == 0 ? 0 : (_currentPage * _ordersPerPage);
    var order = _orders[n + actualizedNumber];
    var baseAmount = assetFormat(order.baseAsset, order.baseAmount);
    return ListTile(
        title: Text('${order.token}'),
        leading: assetLogo(order.baseAsset),
        subtitle: Text(
            '${order.market} - ${marketSideNice(order.side)} $baseAmount ${order.baseAsset} - ${describeEnum(order.status).toUpperCase()}',
            style: order.status == BeOrderStatus.expired ||
                    order.status == BeOrderStatus.cancelled
                ? TextStyle(color: ZapBlackLight)
                : order.status == BeOrderStatus.created ||
                        order.status == BeOrderStatus.ready
                    ? null
                    : TextStyle(color: ZapGreen)),
        onTap: () => _orderTap(order));
  }

  @override
  Widget build(BuildContext context) {
    print('orders length is ${_orders.length}');
    List<Widget> pageButtons = <Widget>[];
    if (_currentPage > 0 && (_currentPage + 1) < _totalPages) {
      pageButtons = 
      <Widget>[
        GestureDetector(
          child: 
	    Container(
	      width: 40,
	      height: 40,
	      child: Center(
		  child: Text('${_currentPage}',
		      textAlign: TextAlign.center,
		      style: TextStyle(color: Colors.white))),
	      decoration: BoxDecoration(
		shape: BoxShape.circle,
		color: Colors.grey,
	      ),
	    ),
          onTap: (){
            setState(
              () {
                _currentPage--;
              }
            );
          },
        ),
	Container(
	  width: 40,
	  height: 40,
	  child: Center(
	      child: Text('${_currentPage + 1}',
		  textAlign: TextAlign.center,
		  style: TextStyle(color: Colors.white))),
	  decoration: BoxDecoration(
	    shape: BoxShape.circle,
	    color: Colors.blue.shade400,
	  ),
	),
        GestureDetector(
          child: 
	    Container(
	      width: 40,
	      height: 40,
	      child: Center(
		  child: Text('${_currentPage + 2}',
		      textAlign: TextAlign.center,
		      style: TextStyle(color: Colors.white))),
	      decoration: BoxDecoration(
		shape: BoxShape.circle,
		color: Colors.grey,
	      ),
	    ),
          onTap: (){
            setState(
              () {
                _currentPage++;
              }
            );
          },
        ),

      ];
    } else if (_currentPage > 0) {
      pageButtons =
	<Widget>[
	  GestureDetector(
	    child: 
	      Container(
		width: 40,
		height: 40,
		child: Center(
		    child: Text('${_currentPage}',
			textAlign: TextAlign.center,
			style: TextStyle(color: Colors.white))),
		decoration: BoxDecoration(
		  shape: BoxShape.circle,
		  color: Colors.grey,
		),
	      ),
	    onTap: (){
	      setState(
		() {
		  _currentPage--;
		}
	      );
	    },
	  ),
	  Container(
	    width: 40,
	    height: 40,
	    child: Center(
		child: Text('${_currentPage + 1}',
		    textAlign: TextAlign.center,
		    style: TextStyle(color: Colors.white))),
	    decoration: BoxDecoration(
	      shape: BoxShape.circle,
	      color: Colors.blue.shade400,
	    ),
	  ),
	];
    } else if ((_currentPage + 1) < _totalPages) {
      pageButtons =
	<Widget>[
	  Container(
	    width: 40,
	    height: 40,
	    child: Center(
		child: Text('${_currentPage + 1}',
		    textAlign: TextAlign.center,
		    style: TextStyle(color: Colors.white))),
	    decoration: BoxDecoration(
	      shape: BoxShape.circle,
	      color: Colors.blue.shade400,
	    ),
	  ),
	  GestureDetector(
	    child: 
	      Container(
		width: 40,
		height: 40,
		child: Center(
		    child: Text('${_currentPage + 2}',
			textAlign: TextAlign.center,
			style: TextStyle(color: Colors.white))),
		decoration: BoxDecoration(
		  shape: BoxShape.circle,
		  color: Colors.grey,
		),
	      ),
	    onTap: (){
	      setState(
		() {
		  _currentPage++;
		}
	      );
	    },
	  ),
	];
    } else {
      pageButtons =
	<Widget>[
	  Container(
	    width: 40,
	    height: 40,
	    child: Center(
		child: Text('${_currentPage + 1}',
		    textAlign: TextAlign.center,
		    style: TextStyle(color: Colors.white))),
	    decoration: BoxDecoration(
	      shape: BoxShape.circle,
	      color: Colors.blue.shade400,
	    ),
	  ),
	];
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Orders'),
      ),
      body: _orders.length == 0
          ? Center(
              child: Column(children: <Widget>[
              SizedBox(height: 90),
              Text("No orders yet")
            ]))
          : Center(
              child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                ListView.builder(
                    itemBuilder: _listItem,
                    itemCount: ((_orders.length -
                                ((_currentPage + 1) * _ordersPerPage)) > -1)
                        ? _ordersPerPage
                        : (_orders.length - ((_currentPage) * _ordersPerPage)),
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: _currentPage > 0
                      ? ((_currentPage + 1) * _ordersPerPage < _orders.length
                          ? <Widget>[
                              FloatingActionButton(
                                onPressed: () {
                                  setState(() {
                                    _currentPage--;
                                  });
                                },
                                child: const Icon(Icons.arrow_back),
                                backgroundColor: Colors.blue,
                              ),
                              Row(
                                children: pageButtons,
                              ),
                              FloatingActionButton(
                                onPressed: () {
                                  setState(() {
                                    _currentPage++;
                                  });
                                },
                                child: const Icon(Icons.arrow_forward),
                                backgroundColor: Colors.blue,
                              )
                            ]
                          : <Widget>[
                              FloatingActionButton(
                                onPressed: () {
                                  setState(() {
                                    _currentPage--;
                                  });
                                },
                                child: const Icon(Icons.arrow_back),
                                backgroundColor: Colors.blue,
                              ),
                              Container(
                                width: 40,
                                height: 40,
                                child: Center(
                                    child: Text('${_currentPage + 1}',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.white))),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.blue.shade400,
                                ),
                              ),
                              Opacity(
                                opacity: 0,
                                child: FloatingActionButton(
                                  mouseCursor: SystemMouseCursors.basic,
                                  onPressed: () {
                                    setState(() {});
                                  },
                                  child: const Icon(Icons.arrow_back),
                                  backgroundColor: Colors.white,
                                ),
                              ),
                            ])
                      : <Widget>[
                          Opacity(
                            opacity: 0,
                            child: FloatingActionButton(
                              mouseCursor: SystemMouseCursors.basic,
                              onPressed: () {
                                setState(() {});
                              },
                              child: const Icon(Icons.arrow_back),
                              backgroundColor: Colors.white,
                            ),
                          ),
                          Container(
                            width: 40,
                            height: 40,
                            child: Center(
                                child: Text('${_currentPage + 1}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.white))),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue.shade400,
                            ),
                          ),
                          FloatingActionButton(
                            onPressed: () {
                              setState(() {
                                _currentPage++;
                              });
                            },
                            child: const Icon(Icons.arrow_forward),
                            backgroundColor: Colors.blue,
                          ),
                        ],
                ),
              ],
            )),
    );
  }
}
