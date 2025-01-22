pragma solidity 0.8.0;

contract SubscriptionManager {
    address public owner;
    uint public nextSubscriptionId;

    mapping(address => uint) public userSubscriptions;
    mapping(uint => Subscription) public subscriptions;
    
    struct Subscription {
        uint subscriptionFee;
        uint nextPaymentDue;
        bool active;
    }

    event Subscribed(address indexed user, uint subscriptionId, uint fee, uint nextPaymentDue);
    event SubscriptionRenewed(address indexed user, uint subscriptionId, uint nextPaymentDue);
    event SubscriptionCanceled(address indexed user, uint subscriptionId);

    constructor() public {
        owner = msg.sender;
        nextSubscriptionId = 1; // Start subscription IDs from 1
    }

    // Function to subscribe to a service
    function subscribe(uint _subscriptionFee) public payable returns (uint) {
        require(_subscriptionFee > 0, "Subscription fee must be greater than zero");
        require(msg.value >= _subscriptionFee, "Insufficient payment for subscription");

        uint subscriptionId = nextSubscriptionId;
        nextSubscriptionId++;

        subscriptions[subscriptionId] = Subscription({
            subscriptionFee: _subscriptionFee,
            nextPaymentDue: now + 30 days,
            active: true
        });

        userSubscriptions[msg.sender] = subscriptionId;

        emit Subscribed(msg.sender, subscriptionId, _subscriptionFee, now + 30 days);
        return subscriptionId;
    }

    // Function to renew a subscription
    function renewSubscription() public payable {
        uint subscriptionId = userSubscriptions[msg.sender];
        require(subscriptionId > 0, "You are not subscribed");

        Subscription storage userSubscription = subscriptions[subscriptionId];
        require(userSubscription.active, "Subscription is not active");
        require(now >= userSubscription.nextPaymentDue, "Subscription is not due for renewal");
        require(msg.value >= userSubscription.subscriptionFee, "Insufficient payment to renew");

        userSubscription.nextPaymentDue = now + 30 days;

        emit SubscriptionRenewed(msg.sender, subscriptionId, now + 30 days);
    }

    // Function to cancel the subscription
    function cancelSubscription() public {
        uint subscriptionId = userSubscriptions[msg.sender];
        require(subscriptionId > 0, "You are not subscribed");

        Subscription storage userSubscription = subscriptions[subscriptionId];
        require(userSubscription.active, "Subscription is not active");

        userSubscription.active = false;

        emit SubscriptionCanceled(msg.sender, subscriptionId);
    }

    // Function to check subscription details
    function getSubscriptionDetails(address user) public view returns (uint, uint, bool) {
        uint subscriptionId = userSubscriptions[user];
        require(subscriptionId > 0, "User is not subscribed");

        Subscription memory userSubscription = subscriptions[subscriptionId];
        return (userSubscription.subscriptionFee, userSubscription.nextPaymentDue, userSubscription.active);
    }

    // Owner withdraw function to retrieve contract balance
    function withdrawFunds() external {
        require(msg.sender == owner, "Only the owner can withdraw funds");
        address(uint160(owner)).transfer(address(this).balance);
    }
}
