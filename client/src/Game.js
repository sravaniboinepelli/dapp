import './App.css';
import Web3 from "web3"
import React, { Component } from "react";
import { Button, DropdownButton, Dropdown, ButtonGroup, Form } from "react-bootstrap";
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import { faSquare, faDiceOne, faDiceThree, faDiceTwo, faDiceFour, faDiceFive, faDiceSix } from '@fortawesome/free-solid-svg-icons'
import SetString from './components/SetString'

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
        numActiveKey:null,
        getDiceKey:null,
        numPlayersPaid:0,
        shuffleDice:null,
        submitCount: 0,
        accounts:[]
      };
      this.AssignDice = this.AssignDice.bind(this);
      this.ShuffleDice = this.ShuffleDice.bind(this);
      this.Challenge = this.Challenge.bind(this);
      this.RaiseBet = this.RaiseBet.bind(this);
      this.handleSubmit = this.handleSubmit.bind(this);
      
      var no_dice = []
    }

    async componentDidMount(){
      const web3 = new Web3(window.web3.currentProvider)
      web3.eth.getBlock('latest').then(console.log)
      const accountsl =  web3.eth.getAccounts(); 
      console.log("accounts1", accountsl)
        const { drizzle } = this.props;
        const contract = drizzle.contracts.Liars;
        const _numActiveKey = contract.methods["numActivePlayers"].cacheCall();
        const _getDiceKey = contract.methods["getRolledDice"].cacheCall();

        this.setState({ numActiveKey:_numActiveKey,
        getDiceKey:_getDiceKey });
        this.setState({accounts: accountsl});

    }
    AssignDice() {
        this.diceshuffle();
        var no_dice = []
        var og_dice = this.state.og_dice;
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
        const { Liars } = this.props.drizzleState.contracts;
        const getRolledDice = Liars.getRolledDice[this.state.getDiceKey].value;
        var newconfig = []
        for(var j = 0; j<this.state.config.length;j++){
          var row = []
          for(var k = 0; k<this.state.config[j].length;k++)
          {
            row.push(this.state.config[j][k]);
          }
          newconfig.push(row);
        }
        for(var i = 0; i<getRolledDice.length;i++)
        {
          if(getRolledDice[i]!=0){
              newconfig = getRolledDice[this.state.curr][i];
          }
        }
        console.log(getRolledDice.value);
      }

      diceshuffle = () => {
        const contract = this.props.drizzle.contracts.Liars;
        //let drizzle know we want to call the `set` method with `value`
        console.log("account", this.props.drizzleState.accounts[0] )
        const stackId = contract.methods["DiceShuffle"].cacheSend({
          from: this.props.drizzleState.accounts[0]
        });
      }

      ShuffleDice() {
        var no_players = this.state.no_players;
        var config = []
        for (var i = 0; i < no_players; i++) {
          var player_config = [];
          for (var j = 0; j < this.state.no_dice[i]; j++)
            player_config.push(1 + Math.floor(Math.random() * 6));
          config.push(player_config);
        }
    
        this.setState({
          config: config
        })
    
      }
    
      Challenge() {
        var curr_moves = this.state.moves;
        var curr = this.state.curr;
        var no_players = this.state.no_players
        this.setChallenge();
        curr_moves.push([0, curr + 1, (curr + no_players - 1) % no_players + 1]);
        this.setState({
          curr: -1,
          diceVal: 0,
          diceNum: 0,
          moves: curr_moves
        })
      }
    
      RaiseBet() {
        if (this.state.diceNum == 0 || this.state.diceVal == 0) {
          alert('Invalid move')
          return;
        }
        this.setBid(this.state.diceNum,this.state.diceVal);
        var turn = (this.state.curr + 1) % this.state.no_players;
        var curr_moves = this.state.moves;
        curr_moves.push([1, this.state.curr + 1, this.state.diceNum, this.state.diceVal]);
        this.setState({
          curr: turn,
          diceNum: 0,
          diceVal: 0,
          topMessage: "Player " + (turn + 1).toString() + "'s Turn",
          moves: curr_moves
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
    
      setPDNo = (no_players, og_dice, drizzle, drizzleState) => {
        const contract = drizzle.contracts.Liars;
        //let drizzle know we want to call the `set` method with `value`
        const stackIdSetPD = contract.methods["setPD"].cacheSend(no_players, og_dice, {
          from: drizzleState.accounts[0]
        });

        var i =0;
        console.log("account", drizzleState.accounts[i], drizzleState.accounts[0])
        for (var i=0; i< no_players; i++){
            contract.methods["initialpay"].cacheSend( {
            from: drizzleState.accounts[i],
            value: 0x2,
          });

        }
    
        //save the `stackId` for later reference
        // this.setState({ stackIdSetPD });

      };
    
      //The same format is to be used for getters. Replace numActivePlayers with the getter name
      readPlayer = () => {
        console.log(this.props.drizzleState.contracts.Liars.numActivePlayers[this.state.numActiveKey].value)
        const { Liars } = this.props.drizzleState.contracts;
        console.log(Liars);
        const numPlayersPaid = Liars.numActivePlayers[this.state.numActiveKey];
        console.log("LOLLL",numPlayersPaid.value);
        this.state.numPlayersPaid = numPlayersPaid.value
        ;
      }
      
      setChallenge = () => {
        const contract = this.props.drizzle.contracts.Liars;
        const stackId = contract.methods["Challenge"].cacheSend({
          from: this.props.drizzleState.accounts[0]
        });
      }

      setBid = (numDice,faceValue) => {
        const contract = this.props.drizzle.contracts.Liars;
        const stackId = contract.methods["Bet"].cacheSend(numDice,faceValue,{
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
        if (!this.state.no_players || !this.state.og_dice) {
          alert("Choose appropriate value");
          return;
        }
        this.setPDNo(this.state.no_players, this.state.og_dice, this.props.drizzle, this.props.drizzleState);
        this.setState({submitCount: this.state.submitCount++})
        if (this.state.submitCount == 1){
          this.state.numPlayersPaid = 2;
        }

        this.readPlayer(this.props.drizzle,this.props.drizzleState);
        console.log(this.state.numPlayersPaid);
        if(this.state.no_players!=0&&this.state.numPlayersPaid!=0&&this.state.no_players==this.state.numPlayersPaid){
          this.setState({
            isSubmitted: 1
          }, () => {
            this.AssignDice();
            console.log(this.state.isSubmitted);
            console.log("WOOHOO!");
          })
        }
      }
      render() {
        var mapping = { 1: faDiceOne, 2: faDiceTwo, 3: faDiceThree, 4: faDiceFour, 5: faDiceFive, 6: faDiceSix }
        var info = [1, 2, 3, 4, 5, 6]
        if (!this.props.drizzleState.drizzleStatus.initialized) return "LOADSING DRIZZLE";
        return (
          <div className="App">
            <div className="page">
              <h1>{this.state.topMessage}</h1>
              {((!this.state.isSubmitted)) ?
                <div>
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
    
                    <button type="submit" class="btn btn-primary mb-2" onClick={this.handleSubmit}>Submit</button>
                  </div>
                </div>
                :
                <div>
                  <table className="center mt-3">
                    <tbody>
                      {this.state.config.map((row, index) => (
                        <tr>
    
                          {row.map((col, ind) => { return index === this.state.curr || this.state.curr === -1 ? <td><FontAwesomeIcon className="mr-2 mb-2 ml-2" icon={mapping[col]} size="4x"></FontAwesomeIcon></td> : <td><FontAwesomeIcon icon={faSquare} size="4x" className="mr-2 mb-2 ml-2"></FontAwesomeIcon></td> }
                          )}
                        </tr>
    
                      ))}
                    </tbody>
                  </table>
    
                  <Button variant="danger" className="mt-4 mr-4" onClick={this.Challenge}>Challenge</Button>
                  <Button className="mt-4 mr-4" onClick={this.getDice}>GetDiceFaces</Button>
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
    
                  <Button className="mt-4 mr-4" onClick={this.RaiseBet}>Raise Bet</Button>
                  <div className="mt-4">
                    {this.state.moves.length > 0 && <h3>Game log</h3>}
    
                    {
                      this.state.moves.reverse().map((move, ind) => { return move[0] === 0 ? <p>Player {move[1]} challenged player {move[2]}</p> : <p>Player {move[1]} raised {move[2]} dices of value {move[3]}</p> })
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
