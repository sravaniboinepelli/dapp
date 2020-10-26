import './App.css';
import gif from "./img/jack.gif"
import "bootstrap/dist/css/bootstrap.min.css";
import React, { Component } from "react";
import { Button, DropdownButton, Dropdown, ButtonGroup, Form } from "react-bootstrap";
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import { faSquare, faDiceOne, faDiceThree, faDiceTwo, faDiceFour, faDiceFive, faDiceSix } from '@fortawesome/free-solid-svg-icons'

export default class Game extends React.Component {
	constructor(props) {
		super(props);

		this.state = {
			stackId: null,
			no_players: 0,
			og_dice: 0,
			no_dice: [],
			config: [],
			curr: 0,
			diceVal: 0,
			diceNum: 0,
			topMessage: "Liar's Dice Game",
			moves: [],
			isSubmitted: 0,
			numActiveKey: null,
			getDiceKey: null,
			numPlayersPaid: 0,
			shuffleDice: null,
			submitCount: 0,
			og_diceKey: null,
			num_playersKey: null,
			no_diceKey: null,
			isSubmittedKey: null,
			currKey: null,
			bidKey: null,
			currentturnKey: null,
			currentturnnoKey: null,
			isGameEndedKey: null,
			accounts: [],
			diceVisible: 0,
			winningPlayerKey: null,
		};
		this.AssignDice = this.AssignDice.bind(this);
		this.ShuffleDice = this.ShuffleDice.bind(this);
		this.Challenge = this.Challenge.bind(this);
		this.RaiseBet = this.RaiseBet.bind(this);
		this.handleSubmit = this.handleSubmit.bind(this);

		var no_dice = []
	}

	componentDidMount() {
		const { drizzle } = this.props;
		const contract = drizzle.contracts.LiarsDice;
		const _numActiveKey = contract.methods["numActivePlayers"].cacheCall();
		const _getDiceKey = contract.methods["getRolledDice"].cacheCall();
		const _og_diceKey = contract.methods["numSetDice"].cacheCall();
		const _num_playersKey = contract.methods["numPlayers"].cacheCall();
		//const no_diceKey = contract.methods["numDiceList"].cacheCall();
		const _isSubmittedKey = contract.methods["isSubmitted"].cacheCall();
		const _currKey = contract.methods["turnOfPlayer"].cacheCall();
		const _bidKey = contract.methods["currentBid"].cacheCall();
		const _currentturnKey = contract.methods["currentturn"].cacheCall();
		const _currentturnnoKey = contract.methods["currentturnno"].cacheCall();
		const _isGameEndedKey = contract.methods["isGameEnded"].cacheCall();
		const _winningPlayerKey = contract.methods["winningPlayer"].cacheCall();

		this.setState({
			numActiveKey: _numActiveKey,
			getDiceKey: _getDiceKey,
			numPlayersPaid: 0,
			og_diceKey: _og_diceKey,
			num_playersKey: _num_playersKey,
			//_no_diceKey:no_diceKey,
			isSubmittedKey: _isSubmittedKey,
			currKey: _currKey,
			bidKey: _bidKey,
			currentturnKey: _currentturnKey,
			currentturnnoKey: _currentturnnoKey,
			isGameEndedKey: _isGameEndedKey,
			winningPlayerKey: _winningPlayerKey
		});
		// this.setState({accounts: accountsl});

	}
	AssignDice() {
		const { LiarsDice } = this.props.drizzleState.contracts;
		this.diceshuffle();
		var og_dice = LiarsDice.numSetDice[this.state.og_diceKey].value;
		var no_dice = []
		// var og_dice = this.state.og_dice;
		// var no_players = LiarsDice.numSetDice[this.state._og_diceKey].value;
		for (var i = 0; i < this.state.no_players; i++)
			no_dice.push(og_dice);

		this.setState({
			no_dice: no_dice
		}, () => {
			this.ShuffleDice();
		})
	}

	getDice = () => {
		// save the `dataKey` to local component state for later reference
		const { LiarsDice } = this.props.drizzleState.contracts;
		const { drizzle } = this.props;
		console.log(LiarsDice, this.state.getDiceKey)
		const getRolledDice = LiarsDice.getRolledDice[this.state.getDiceKey];
		const curr = LiarsDice.turnOfPlayer[this.state.currKey];
		const config = (getRolledDice && getRolledDice.value);
		this.setState({ config })
	}

	diceshuffle = () => {
		const contract = this.props.drizzle.contracts.LiarsDice;
		//let drizzle know we want to call the `set` method with `value`
		console.log("account", this.props.drizzleState.accounts[0])
		const stackId = contract.methods["DiceShuffle"].cacheSend({
			from: this.props.drizzleState.accounts[0]
		});
	}

	ShuffleDice() {
		const { LiarsDice } = this.props.drizzleState.contracts;
		var no_players = LiarsDice.numPlayers[this.state.num_playersKey].value;
		//var numDice = LiarsDice.numDiceList[this.state._no_diceKey].value;
		// var no_players = this.state.no_players;
		var numDice = this.state.no_dice;
		var config = []
		for (var i = 0; i < no_players; i++) {
			var player_config = [];
			for (var j = 0; j < numDice[i]; j++)
				player_config.push(0);
			config.push(player_config);
		}

		this.setState({
			config: config
		})

	}

	Challenge() {
		const { LiarsDice } = this.props.drizzleState.contracts;
		const currTurnMeta = this.props.drizzleState.accounts[0];
		const currTurnAddr = LiarsDice.currentturn[this.state.currentturnKey];
		const currBid = LiarsDice.currentBid[this.state.bidKey];

		
		if (currTurnAddr) {
			if (currTurnAddr.value != currTurnMeta) {
				alert("Please wait for your turn :)");
				return;
			}
		}

		if(currBid) 
		{
			if(currBid.value.faceValue=="0")
			{
				alert("Yours is the first move!");
				return;
			}
		}
		var curr_moves = this.state.moves;
		var curr = this.state.curr;
		var no_players = this.state.no_players
		this.setChallenge();
		curr_moves.push([0, curr + 1, (curr + no_players - 1) % no_players + 1]);
		this.setState({
			curr: -1,
			diceVal: 0,
			diceNum: 0,
			moves: curr_moves,
			diceVisible: 0,
		})
	}
	handlePay = () => {
		// console.log(this.props.drizzleState.accounts[0]);
		const contract = this.props.drizzle.contracts.LiarsDice;
		const stackIdSetPD = contract.methods["initialpay"].cacheSend({
			from: this.props.drizzleState.accounts[0], value: 1
		});
	}
	RaiseBet() {
		const { LiarsDice } = this.props.drizzleState.contracts;
		const currTurnMeta = this.props.drizzleState.accounts[0];
		const currTurnAddr = LiarsDice.currentturn[this.state.currentturnKey];
		const currBid = LiarsDice.currentBid[this.state.bidKey];

		if (currTurnAddr) {
			if (currTurnAddr.value != currTurnMeta) {
				alert("Please wait for your turn :)");
				return;
			}

		}

		if (this.state.diceNum == 0 || this.state.diceVal == 0) {
			alert('Invalid move')
			return;
		}
		if(currBid)
		{
			if(this.state.diceNum <= currBid.value.numDice && this.state.diceVal <= currBid.value.faceValue)
			{
				alert('Invalid move')
				return;
			} 
		}
		// console.log("BID",currBid && currBid.value);
		var curr_moves = this.state.moves;
		var currTurnNo = LiarsDice.currentturnno[this.state.currentturnnoKey];
		var curr = currTurnNo && currTurnNo.value;
		if(curr) curr= parseInt(curr) +1;
		curr_moves.push([1, curr, this.state.diceNum, this.state.diceVal]);

		this.setBid(this.state.diceNum, this.state.diceVal);
		this.ShuffleDice();
		currTurnNo = LiarsDice.currentturnno[this.state.currentturnnoKey];
		curr = currTurnNo && currTurnNo.value;
		if(curr) curr= parseInt(curr) +1;
		this.setState({
			curr: curr,
			diceNum: 0,
			diceVal: 0,
			moves: curr_moves,
			diceVisible: 0
		})
	}

	HandleNumber = (e) => {
		this.setState({
			diceNum: parseInt(e)
		})
	}

	HandleValue = (e) => {
		this.setState({
			diceVal: parseInt(e)
		})
	}

	HandlePlayer = (e) => {
		this.setState({
			no_players: parseInt(e)
		})
	}

	setPDNo = (no_players, og_dice) => {

		const contract = this.props.drizzle.contracts.LiarsDice;
		//let drizzle know we want to call the `set` method with `value`
		const stackIdSetPD = contract.methods["setPD"].cacheSend(no_players, og_dice, {
			from: this.props.drizzleState.accounts[0]
		});
	}

	setRolledDice = () => {
		// console.log(this.props.drizzleState.accounts[0]);
		const { LiarsDice } = this.props.drizzleState.contracts;
		const currTurnMeta = this.props.drizzleState.accounts[0];
		const currTurnAddr = LiarsDice.currentturn[this.state.currentturnKey];
		var flag = 0;

		if(currTurnAddr)
		{
			if(currTurnAddr.value != currTurnMeta)
			{
				alert("Please wait for your turn :)");
				return;
			}
			else{
				this.setState({diceVisible: 1})
			}
		}
		
		const contract = this.props.drizzle.contracts.LiarsDice;
		//let drizzle know we want to call the `set` method with `value`
		const stackIdSetPD = contract.methods["setRolledDice"].cacheSend({
			from: this.props.drizzleState.accounts[0]
		});


	}

	//The same format is to be used for getters. Replace numActivePlayers with the getter name
	readPlayer = () => {
		const { LiarsDice } = this.props.drizzleState.contracts;
		console.log(this.state.numActiveKey);
		const numPlayersPaid = LiarsDice.numActivePlayers[this.state.numActiveKey];
		console.log("LOLLL", numPlayersPaid && numPlayersPaid.value);
		this.state.numPlayersPaid = numPlayersPaid && numPlayersPaid.value
			;
	}

	setChallenge = () => {
		const contract = this.props.drizzle.contracts.LiarsDice;
		const stackId = contract.methods["Challenge"].cacheSend({
			from: this.props.drizzleState.accounts[0]
		});
	}

	setBid = (numDice, faceValue) => {
		const contract = this.props.drizzle.contracts.LiarsDice;
		const stackId = contract.methods["Bet"].cacheSend(numDice, faceValue, {
			from: this.props.drizzleState.accounts[0]
		});
	}



	HandleDice = (e) => {
		this.setState({
			og_dice: parseInt(e)
		})
	}

	handleForm = (event) => {
		let nam = event.target.name;
		let val = event.target.value;
		this.setState({ [nam]: val });
		console.log({ [nam]: val });
	}

	handleSubmit() {
		const { LiarsDice } = this.props.drizzleState.contracts;
		if (!this.state.no_players || !this.state.og_dice) {
			alert("Choose appropriate value");
			return;
		}
		
		if(this.state.no_players==1){
			alert("Not enough players");
			return;
		}

		this.readPlayer(this.props.drizzle, this.props.drizzleState);
		console.log(this.state.numPlayersPaid);
		if (this.state.no_players != 0 && this.state.numPlayersPaid != 0 && this.state.no_players == this.state.numPlayersPaid) {
			this.setState({
				isSubmitted: 1
			}, () => {
				this.AssignDice();
			})
		}

		else
		{
			alert("Number of transactions do not match number of players!");
			return;
		}
		this.setPDNo(this.state.no_players, this.state.og_dice);
		
	}
	render() {
		const { LiarsDice } = this.props.drizzleState.contracts;
		// const og_dice = LiarsDice.numSetDice[this.state._og_diceKey].value;
		// const num_player = LiarsDice.numPlayers[this.state._num_playersKey].value;
		const isSubmitted = LiarsDice.isSubmitted[this.state.isSubmittedKey];
		// const curr = LiarsDice.turnOfPlayer[this.state._currKey].value;
		// const numActivePlayer = LiarsDice.numActivePlayers[this.state._numActiveKey].value;
		const getDiceEye = LiarsDice.getRolledDice[this.state.getDiceKey];
		const isGameEnded = LiarsDice.isGameEnded[this.state.isGameEndedKey];
		const currBid = LiarsDice.currentBid[this.state.bidKey];
		const playerWon = LiarsDice.winningPlayer[this.state.winningPlayerKey];
		var getDice = [0]
		if(getDiceEye!=null)
		{
			getDice = getDiceEye.value;
		}

		var moves = []
		if(currBid)
		{
			if(currBid.value.faceValue !=0)
			{
				moves.push(currBid.value.faceValue);
				moves.push(currBid.value.numDice);
			}
		}
		// console.log("CURR BID",currBid && currBid.value);
		// const numDice = LiarsDice.numDiceList[this.state._no_diceKey].value;
		// const _numActiveKey = contract.methods["numActivePlayers"].cacheCall();
		// const _getDiceKey = contract.methods["getRolledDice"].cacheCall();
		// const _og_diceKey = contract.methods["numSetDice"].cacheCall();
		// const _num_playersKey = contract.methods["numPlayers"].cacheCall();
		// const _no_diceKey = contract.methods["numDiceList"].cacheCall();
		// const _isSubmittedKey = contract.methods["isSubmitted"].cacheCall();
		// const _currKey = contract.methods["turnOfPlayer"].cacheCall();
		const currTurnMeta = this.props.drizzleState.accounts[0];
		const currTurnAddr = LiarsDice.currentturn[this.state.currentturnKey];
		const currTurnNo = LiarsDice.currentturnno[this.state.currentturnnoKey];
		console.log("CURR TURN", currTurnNo && currTurnNo.value);
		console.log("CURR BID", currBid && currBid.value)
		var flag = 0;
		if(currTurnAddr)
		{
			if(currTurnAddr.value == currTurnMeta)
				flag = 1;
			
			// console.log("LOL",currTurnAddr.value,currTurnMeta)
		}
		var turn = 1;
		if(currTurnNo)
			turn = parseInt(currTurnNo.value)+1;
		const numPlayersPaid = LiarsDice.numActivePlayers[this.state.numActiveKey];
		// console.log("RENDER",numPlayersPaid && numPlayersPaid.value);
		// console.log("DICEFACES:",(getDice && getDice.value));
		var mapping = { 1: faDiceOne, 2: faDiceTwo, 3: faDiceThree, 4: faDiceFour, 5: faDiceFive, 6: faDiceSix }
		var info = [1, 2, 3, 4, 5, 6]
		// console.log("HAS THE GAME ENDED?",(isGameEnded&&isGameEnded.value));
		if (isGameEnded && isGameEnded.value) {
			var won = ""
			if (isGameEnded.value == 2)
			{
				return <div><h1 class="mt-5">Player {playerWon && playerWon.value.playerNo} wins the game!</h1><img className="mt-5" src={gif} alt="loading..." /></div>
			}
		}
		return (
			<div className="App">
				<div className="page">
					{((!(isSubmitted && isSubmitted.value))) ?
						<div>
							<h1>Liar's Dice Game</h1>
							<div class="middle">
								<select class="form-control" name="no_players" value={this.state.value} onChange={this.handleForm}>
									<option selected disabled>Number of Players</option>

									{
										info.map((val, ind) => {
											return <option value={val}>{val}</option>
										})
									}
								</select>
								<br />

								<select class="form-control" title="Number" name="og_dice" value={this.state.value} onChange={this.handleForm}>
									<option selected disabled>Number of Dice</option>
									{
										info.map((val, ind) => {
											return <option value={val}>{val}</option>
										})
									}
								</select>
								<br />

								<button type="submit" class="btn btn-primary mb-2 mr-4" onClick={this.handleSubmit}>Submit</button>
								<button type="submit" class="btn btn-success mb-2" onClick={this.handlePay}>Pay</button>
							</div>
						</div>
						:
						<div>
							<h1>Player {turn}'s turn</h1>
							<table className="center mt-3">
								<tbody>
									<tr>
									{ 
										getDice.map((col, index) => { return (col != 0 && flag == 1 && this.state.diceVisible) ? <td><FontAwesomeIcon className="mr-2 mb-2 ml-2" icon={mapping[col]} size="4x"></FontAwesomeIcon></td>:"" })
									}
									</tr>

								</tbody>
							</table>

							{/* <Button className="mt-4 mr-4" onClick={this.getDice}>GetDiceFaces</Button> */}
							<Button className="mt-4 mr-4" onClick={this.setRolledDice}>View Dice</Button>
							<Button variant="danger" className="mt-4 mr-4" onClick={this.Challenge}>Challenge</Button>

							<br />
							<Dropdown as={ButtonGroup} className="mr-4 mt-4" onSelect={this.HandleNumber}>
								<Dropdown.Toggle variant="info" id="dropdown-custom-1">Dice Number</Dropdown.Toggle>
								<Dropdown.Menu>
									{
										info.map((val, ind) => {
											return <Dropdown.Item eventKey={val}>{val}</Dropdown.Item>
										})
									}
								</Dropdown.Menu>
							</Dropdown>{' '}
							<Dropdown as={ButtonGroup} onSelect={this.HandleValue}>
								<Dropdown.Toggle variant="info" id="dropdown-custom-1" className="mt-4 mr-4">Dice Value</Dropdown.Toggle>
								<Dropdown.Menu>
									{
										info.map((val, ind) => {
											return <Dropdown.Item eventKey={val}>{val}</Dropdown.Item>
										})
									}
								</Dropdown.Menu>

							</Dropdown>

							<Button className="mt-4 mr-4" variant="info" onClick={this.RaiseBet}>Raise Bet</Button>
							<div className="mt-4">
								{moves.length > 0 && <h3>Game log</h3>}
								{
									<p>Latest bet: {moves[0]} dices of value {moves[1]}</p> 
								}
							</div>
						</div>
					}
				</div>
			</div>

		);
	}
	getTxStatus = () => {
		// get the transaction states from the drizzle state
		const { transactions, transactionStack } = this.props.drizzleState;

		// get the transaction hash using our saved `stackId`
		const txHash = transactionStack[this.state.stackId];

		// if transaction hash does not exist, don't display anything
		if (!txHash) return null;

		// otherwise, return the transaction status
		return `Transaction status: ${transactions[txHash] && transactions[txHash].status}`;
	};

}