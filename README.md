# SimpleVPN
This is a simple ios app for a VPN connection.

Many thanks to [@hamzaozturk](https://github.com/hamzaozturk) for maintaining.

![simulator screen shot dec 23 2016 2 45 33 pm](https://cloud.githubusercontent.com/assets/9286092/21451170/c10e903e-c91e-11e6-9c90-4897de4c0892.png)

## Demo server

To test the connection I would recommend to lunch your own server. With docker, it is as simple as a run single command. Here is great docker image for that [hwdsl2/docker-ipsec-vpn-server](https://github.com/hwdsl2/docker-ipsec-vpn-server).

**Deprecated**
Credentials for testing you can get after registration in account settings on [HidemanVPN site](hideman.net).
At the bottom of the account page you will find: `Username`, `Password`, `IPSec Pre-Shared Key` and servers list like this:

![screen shot 2016-12-24 at 1 19 26 pm](https://cloud.githubusercontent.com/assets/9286092/21466938/f3b5f42c-c9fb-11e6-883b-fb88d3e753fe.png)

IKEv2 requires address NOT IP. On screenshot "DE97" => input in app "DE97.hmn.me".
