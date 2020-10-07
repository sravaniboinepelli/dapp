import React, { Component } from "react";
import { Button, DropdownButton, Dropdown, ButtonGroup } from "react-bootstrap";
import styles from "../App.css";
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import { faSquare, faDiceOne, faDiceThree, faDiceTwo, faDiceFour, faDiceFive, faDiceSix } from '@fortawesome/free-solid-svg-icons'

export default class Gaming extends Component {
  constructor(props) {
    super(props);

    this.state = {
      no_players: 5,
      og_dice: 5,
      no_dice: [],
      config: [],
      curr: 0,
      diceVal: 0,
      diceNum: 0,
      topMessage: "Liar's Dice Game",
      moves: []
    };

    this.AssignDice = this.AssignDice.bind(this);
    this.ShuffleDice = this.ShuffleDice.bind(this);
    this.Challenge = this.Challenge.bind(this);
    this.RaiseBet = this.RaiseBet.bind(this);
    this.HandleNumber = this.HandleNumber.bind(this);
    this.HandleValue = this.HandleValue.bind(this);

    this.AssignDice();
    this.ShuffleDice();
  }

  AssignDice() {
    var no_dice = []
    var og_dice = this.state.og_dice;
    for (var i = 0; i < this.state.no_players; i++)
      no_dice.push(og_dice);
    this.state.no_dice = no_dice;
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

    this.state.config = config;
  }

  Challenge() {
    var curr_moves = this.state.moves;
    var curr = this.state.curr;
    var no_players = this.state.no_players
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

  render() {
    var mapping = { 1: faDiceOne, 2: faDiceTwo, 3: faDiceThree, 4: faDiceFour, 5: faDiceFive, 6: faDiceSix }
    return (
      <div className="page">
        <h1>{this.state.topMessage}</h1>
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
        <Dropdown as={ButtonGroup} className="mr-4 mt-4" onSelect={this.HandleNumber}>
          <Dropdown.Toggle variant="info" id="dropdown-custom-1">Dice Number</Dropdown.Toggle>
          <Dropdown.Menu>
            <Dropdown.Item eventKey="1">1</Dropdown.Item>
            <Dropdown.Item eventKey="2">2</Dropdown.Item>
            <Dropdown.Item eventKey="3">3</Dropdown.Item>
            <Dropdown.Item eventKey="4">4</Dropdown.Item>
            <Dropdown.Item eventKey="5">5</Dropdown.Item>
            <Dropdown.Item eventKey="6">6</Dropdown.Item>
          </Dropdown.Menu>
        </Dropdown>{' '}
        <Dropdown as={ButtonGroup} onSelect={this.HandleValue}>
          <Dropdown.Toggle variant="info" id="dropdown-custom-1" className="mt-4 mr-4">Dice Value</Dropdown.Toggle>
          <Dropdown.Menu>
            <Dropdown.Item eventKey="1">1</Dropdown.Item>
            <Dropdown.Item eventKey="2">2</Dropdown.Item>
            <Dropdown.Item eventKey="3">3</Dropdown.Item>
            <Dropdown.Item eventKey="4">4</Dropdown.Item>
            <Dropdown.Item eventKey="5">5</Dropdown.Item>
            <Dropdown.Item eventKey="6">6</Dropdown.Item>
          </Dropdown.Menu>
        </Dropdown>

        <Button className="mt-4 mr-4" onClick={this.RaiseBet}>Raise Bet</Button>
        <div className="mt-4">
          {this.state.moves.length > 0 && <h3>Game log</h3>}

        {
          this.state.moves.reverse().map((move, ind) => { console.log(move); return move[0] === 0 ? <p>Player {move[1]} challenged player {move[2]}</p> : <p>Player {move[1]} raised {move[2]} dices of value {move[3]}</p> })
        }
        </div>
      </div>

    );
  }
}
