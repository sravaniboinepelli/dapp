import React from 'react';
import './App.css';
import ReadString from "./ReadString";
import SetString from "./SetString";
import "bootstrap/dist/css/bootstrap.min.css";
import { Navbar, Nav, Button } from "react-bootstrap";
import Landing from "./components/Landing";
import Error from "./components/404";


class App extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      loading: true,
      drizzleState: null
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
            <Navbar.Brand href="#home">Liar's Dice</Navbar.Brand>
            <Nav className="mr-auto">
            </Nav>
            <Nav>
              <Nav.Link href="#rules">Rules</Nav.Link>
              <Nav.Link href="#play">Play</Nav.Link>
            </Nav>
          </div>
        </Navbar>

        <Error/>
      
      </div>
    );
  }
}

export default App;
