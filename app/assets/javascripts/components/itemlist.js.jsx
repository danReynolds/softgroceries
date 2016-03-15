var ItemList = React.createClass({
    mixins: [RevealMixin],
    propTypes: {
        users: React.PropTypes.array.isRequired,
        grocery: React.PropTypes.object.isRequired,
        items: React.PropTypes.object.isRequired
    },

    getInitialState: function() {
        return {
            users: this.props.users,
            selection: []
        }
    },

    handleRemove: function(index) {
        this.saveSelection(React.addons.update(this.state.selection, {$splice: [[index, 1]]}));
    },

    handleSave: function() {
        this.saveSelection(this.state.selection);
    },

    saveSelection: function(selection) {
        $.ajax({
            method: 'PATCH',
            data: JSON.stringify({
                grocery: {
                    items: selection.map(function(item) {
                        return {
                            name: item.name,
                            id: item.id,
                            quantity: item.quantity,
                            price: item.price
                        }
                    })
                }
            }),
            dataType: 'json',
            contentType: 'application/json',
            url: this.props.grocery.url
        }).done(function() {
            this.setState({ items: selection });
        }.bind(this));
    },

    reloadItems: function() {
        $.getJSON(this.props.items.url, function(selection) {
            this.setState({ selection: selection });
            $('.collapsible').collapsible({ accordion: false });
            Materialize.initializeDismissable();
        }.bind(this));
    },

    componentDidMount: function() {
        $(document).ready(function() {
            this.reloadItems();
            $('item-list').on('remove', '.dismissable', function(e) {
                this.handleRemove(parseInt(e.target.getAttribute('data-index')));
            });
        }.bind(this));
    },

    componentDidUpdate: function(prevProps, prevState) {
        if (!this.state.modalOpen && prevState.modalOpen) {
            this.reloadItems();
        }
    },

    render: function() {
        var requester, noItems, image;

        if (this.state.selection.length === 0) {
            noItems = <div className="no-items">
                          <i className='fa fa-shopping-basket'/>
                          <h2>Your grocery list is empty.</h2>
                      </div>
        }

        if (!this.state.modalOpen) {
            var items = this.state.selection.map(function(item, index) {
                requester = this.state.users.filter(function(user) {
                    return user.id == item.requester;
                })[0];

                if (!requester) {
                    return;
                }

                return (
                    <li key={'item-' + index}
                        data-index={index}
                        className='collection-item dismissable'>
                        <div className='collapsible-header'>
                            <img src={requester.gravatar} />
                            <p>
                                <strong>{requester.name}</strong> wants <strong>{item.quantity_formatted}</strong>
                            </p>
                        </div>
                        <div className='collapsible-body'>
                            <p>This is a test of the collapsible body.</p>
                        </div>
                    </li>
                );
            }.bind(this));
        }

        return (
            <div className='item-list'>
                <div className='card'>
                    <div className='card-content'>
                        <div className='card-header'>
                            <h3>Groceries for {this.props.grocery.name}</h3>
                        </div>
                        <ul className='collection collapsible popout data-collapsible="accordion'>
                            {noItems}
                            {items}
                        </ul>
                        <a
                            onClick={this.toggleModal}
                            href={"#" + this.props.modal.id}
                            className="btn-floating btn-large waves-effect waves-light">
                            <i className="material-icons">add</i>
                        </a>
                    </div>
                </div>
                <Reveal
                    selection={this.state.selection}
                    modalOpen={this.state.modalOpen}
                    toggleModal={this.toggleModal}
                    handleSave={this.handleSave}
                    addToSelection={this.addToSelection}
                    removeFromSelection={this.removeFromSelection}
                    {...this.props.modal} />
            </div>
        );
    }
});