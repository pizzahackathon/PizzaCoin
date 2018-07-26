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
    'score': 3,
    'detail': [
      {
        'name': 'Game',
        'token': '0xxaaff'
      },
      {
        'name': 'Tot',
        'token': '0xxaagg'
      },
      {
        'name': 'Bank',
        'token': '0xxaahh'
      }
    ]
  },
  {
    'groupId': 'pzc3',
    'groupName': 'hackborbor',
    'score': 3,
    'detail': [
      {
        'name': 'Sittiphol',
        'token': '0xxaaii'
      },
      {
        'name': 'Zent',
        'token': '0xxaakk'
      },
      {
        'name': 'Phuwanai',
        'token': '0xxaall'
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
