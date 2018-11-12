# FLIMNetwork
### 背景

 	由于富聊 IM 系统数据传输采用了 Protobuf 协议，客户端需要配合进行 IM 网络层的改造；此外，现有的 IM 网络层也有诸多问题，比如:

- 职责划分不清晰，通信模块融合了很多业务；

- 扩展性差，添加新的业务就需要修改网络层的代码，造成网络层代码越来越庞大，可读性很差；

- 可复用性差；

  上述问题，可以通过对 IM 网络层重构来解决。

### 设计目标

IM 主流程稳定可用：消息传输具有高可靠性；

IM 网络层结构清晰，职责分离；

高扩展性、可复用性强；

<div STYLE="page-break-after: always;"></div>

### IM 网络层整体结构

![](https://ws1.sinaimg.cn/large/671cb35fly1fp36s5ffqnj216i17kjvt.jpg)

socket 通信管理层：维护 socket 长连接，socket 数据读写

消息处理逻辑层：负责消息发送的预处理，消息的解析、派发

UI 层：展示数据

<div STYLE="page-break-after: always;"></div>

### IM 网络层具体类设计

![](https://ws1.sinaimg.cn/large/671cb35fgy1fp40muyo7aj21og0y4gsw.jpg)

​	网络层的设计主要采用了命令模式，将 IM 消息封装为一个个单独的请求，通过消息调度器将消息发送给底层的 socket 通信模块。

- `FLIMBaseRequest`：这个类是对所有`Request/Response`模式网络请求的抽象，所有这种模式的网络请求都需要继承这个类。

- `FLIMBaseUnrequest`：这个类对应`FLIMBaseRequest`，所有服务端推送过来的消息都需要继承这个类。

- `FLIMScheduler`：所有请求的调度器，主要做了以下几件事情：

  - 通过`FLIMSocketManager`收发数据。
  - 通过`seqNo`和`serviceID`、`commandID`映射`Request`和`Response`，并将服务端的响应派发到正确的`Request`中。
  - 管理请求超时，请求的重发、取消。

- `FLIMSocketManager`：对第三方框架`CocoaAsyncSocket`的封装，主要管理底层的 socket 通信，方便后续的框架更换。 

- `FLRequestProtocol`：`FLIMBaseRequest`需要实现的协议，主要负责请求参数的配置，以及数据的打包、解包。

- `FLUnrequestProtocol`：与`FLRequestProtocol`对应。主要负责 IM 推送的消息的解包。

  <div STYLE="page-break-after: always;"></div>

### 消息收发流程

![](https://ws1.sinaimg.cn/large/671cb35fgy1fp42rzj2kzj21tk0mcwht.jpg)

​	如图所示，向 IM 服务器发送数据，需要先封装一个消息请求，配置好请求参数、消息回调。发送前，根据请求`seqNo`、`serviceID`、`commandID`将请求存入本地的 Map 数据结构中；之后收到服务器推送消息，在本地 Map 数据中找到 请求ID 对应的请求，然后通过回调返回服务器推送的数据。

<div STYLE="page-break-after: always;"></div>

##### 粘包处理

![](http://ww1.sinaimg.cn/bmiddle/87c01ec7gy1fp47ptnm5uj20go0qwq4v.jpg)

<div STYLE="page-break-after: always;"></div>

### socket 长链接的创建与维护

程序启动后，连接 IM 服务器前会先向 JAVA 后台请求 IM 服务器地址端口，然后开始 socket 连接的创建过程；连接成功后，开启消息的收发线程，为了维持长链接，同时会有一个心跳机制。

##### 心跳机制

IM 服务器连接成功后，会开启一个轮询线程，每隔一段时间向 IM 发送一个心跳消息，若客户端若干时间没有收到则视为服务端断开连接。

![](http://ww4.sinaimg.cn/bmiddle/87c01ec7gy1fp4aa6m25pj20k00tgwg4.jpg)

<div STYLE="page-break-after: always;"></div>

##### 重连机制

重连被触发时，重新向 JAVA 后台请求 IM 服务器地址端口，并再次创建连接。

重连触发条件：

- 主动连接socket失败
- 网络被断开
- 心跳机制触发



参考链接：http://blog.makeex.com/2015/05/30/the-architecture-of-teamtalk-mac-client/
