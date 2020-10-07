import React, { Component } from "react";
import { Button } from "react-bootstrap";
import styles from "../App.css";
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import { faSquare, faDiceOne, faDiceThree, faDiceTwo, faDiceFour, faDiceFive, faDiceSix } from '@fortawesome/free-solid-svg-icons'

export default class Gaming extends Component {
  constructor(props) {
    super(props);

    this.AssignDice = this.AssignDice.bind(this);
    this.ShuffleDice = this.ShuffleDice.bind(this)

    this.state = {
      no_players: 5,
      og_dice: 5,
      no_dice: [],
      config: [],
      curr: 0,
    };

    this.AssignDice();
    this.ShuffleDice();
  }

  AssignDice() {
    var no_dice = []
    var og_dice = this.state.og_dice;
    for(var i =0; i <this.state.no_players; i++)
      no_dice.push(og_dice);
    this.state.no_dice = no_dice;
  }

  ShuffleDice(){
    var no_players = this.state.no_players;
    var config = []
    for(var i =0; i <no_players; i++)
    {
      var player_config = [];
      for(var j=0; j<this.state.no_dice[i]; j++)
        player_config.push(1+Math.floor(Math.random() * 6));
      config.push(player_config);
    }

    this.state.config = config;
  }

  render() {
    console.log(this.state.config)
    var mapping = { 1: faDiceOne, 2: faDiceTwo, 3: faDiceThree, 4: faDiceFour, 5: faDiceFive, 6: faDiceSix }
    return (
      <div className="page">
        <h1>Liar's Dice Game</h1>
        <table className="center mt-3">
        <tbody>
          {this.state.config.map((row, index) => (
            <tr>
              
              {row.map((col, ind) =>
                { return index===this.state.curr || this.state.curr === -1 ? <td><FontAwesomeIcon className="mr-2 mb-2 ml-2" icon={mapping[col]} size="4x"></FontAwesomeIcon></td>: <td><FontAwesomeIcon icon={faSquare} size="4x" className="mr-2 mb-2 ml-2"></FontAwesomeIcon></td>}
              )}
            </tr>


          ))}
             </tbody>
        </table>

        <Button variant="danger" className="mt-4 mr-4">Challenge</Button>
        <Button className="mt-4">Raise Bet</Button>
        
      </div>

    );
  }
}
