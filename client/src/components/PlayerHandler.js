export const setValue = (no_players,drizzle,drizzleState) => {
    const contract = drizzle.contracts.LiarsGame;
    console.log("drizzlestate"+drizzleState);
    console.log(drizzle);
    console.log(no_players);
    //let drizzle know we want to call the `set` method with `value`
    const stackId = contract.methods["setPlayer"].cacheSend(no_players, {
        from: drizzleState.accounts[0]
    });

    //save the `stackId` for later reference
    this.setState({ stackId });
};
