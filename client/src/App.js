import React from 'react';
import './App.css';
import ReadString from "./ReadString";
import SetString from "./SetString";
import Game from './Game';
import { Navbar, Nav, Button, NavItem } from "react-bootstrap";
import { Link } from "react-router-dom";

class App extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      loading: true,
      drizzleState: null,
      showRules: 0,
      wander: 0,
    }
  }
  componentDidMount() {
    const { drizzle } = this.props;
    this.unsubscribe = drizzle.store.subscribe(() => {
      const drizzleState = drizzle.store.getState();
      if (drizzleState.drizzleStatus.initialized) {
        this.setState({ loading: false, drizzleState });
      }
    });
  }
  componentWillUnmount() {
    this.unsubscribe();
  }
  render() {
    if (this.state.loading) return "Loading Drizzle...";
    return (
      <div className="App">
        <Navbar bg="dark" variant="dark">
          <div className="container">
            <Navbar.Brand href="/">Liar's Dice</Navbar.Brand>
            <Nav className="mr-auto">
            </Nav>
            <Nav>
              <Nav.Link onClick={() => this.setState({ showRules: 1 })}>Rules</Nav.Link>
              <Nav.Link onClick={() => this.setState({ wander: 1, showRules: 0 })}>Wander</Nav.Link>
            </Nav>

          </div>
        </Navbar>
        {

          this.state.showRules ?
            <div className="landingBody">

              <div className="content">
                <h1 className="heading red-text">Queen Anne's Revenge</h1>
                <h4 className="subheading or-text">
                  Find out who is bluffing and claim the prize!
            </h4>
                <p className="white-text">
                  <ul>
                    <li>
                      A player can choose a dice of any face value and guess its frequency.
                </li>
                    <li>
                      Turns move clockwise, where players can 'raise the bet' or 'challenge'
                </li>
                    <li>
                      An incorrect challenge results in loss of a dice for the person who called the bid
                </li>
                    <li>
                      A correct challenge results in a loss of a dice for the last person
                </li>
                  </ul>
                </p>
              </div>
            </div>
            : [
              (this.state.wander ?
                <div class="page">
                  <h1>Are you lost at sea?</h1>
                  <img class="error" src={require('./img/404-lost-at-sea.gif')} />
                  <br />
                  <Button href="/">Go back to shore</Button>
                </div> : <Game
                  drizzle={this.props.drizzle}
                  drizzleState={this.state.drizzleState}
                />
              )]
        }

      </div>
    );
  }
}

export default App;
