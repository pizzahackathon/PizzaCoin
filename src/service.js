export default class Service {
  constructor (options) {
    this.store = options.store
    this.pizzaCoin = options.pizzaCoin
  }

  setLoading (value) {
    this.store.dispatch('auth/setIsLoading', value)
  }

  async getWallets () {
    const account = await this.pizzaCoin.account
    console.log('getWallets' + account)

    this.store.dispatch('auth/isStaffLogin', account)
    return account
  }
}
