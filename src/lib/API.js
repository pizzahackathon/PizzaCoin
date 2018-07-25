const API_URL = [
  {
    'groupId': 'pzc1',
    'groupName': 'hackmunmun',
    'score': 3,
    'detail': [
      {
        'name': 'Game',
        'token': '0xxaabb'
      },
      {
        'name': 'Tot',
        'token': '0xxaacc'
      },
      {
        'name': 'Bank',
        'token': '0xxaaee'
      }
    ]
  },
  {
    'groupId': 'pzc2',
    'groupName': 'hacknooknook',
    'detail': [
      {
        'name': 'Game',
        'token': '0xxaabb'
      },
      {
        'name': 'Tot',
        'token': '0xxaacc'
      },
      {
        'name': 'Bank',
        'token': '0xxaaee'
      }
    ]
  }
]

export default {
  async getProposal () {
    // const res = await fetch(API_URL)
    const res = API_URL
    // return res.json()
    return res
  }
}
