import test from 'node:test'
import assert from 'node:assert/strict'
import { curlGeometry, shouldCommitCurl } from '../src/page-curl.js'

for (const direction of [-1, 1]) {
  for (const bottom of [false, true]) {
    test(`curl tip follows the drag (${direction}, bottom: ${bottom})`, () => {
      const shape = curlGeometry(400, 600, direction, bottom, 160, 70)
      assert.ok(Math.abs(shape.tip.x - (direction > 0 ? 240 : 160)) < 0.01)
      assert.ok(Math.abs(shape.tip.y - (bottom ? 530 : 70)) < 0.01)
      assert.ok(shape.front.length >= 3 && shape.back.length >= 4)
      assert.ok(shape.radius > 0)
      assert.ok(curlGeometry(400, 600, direction, bottom, 801, 0).front.length === 0)
    })
  }
}

test('settling considers distance and flick direction', () => {
  assert.equal(shouldCommitCurl(5, 400, 1), false)
  assert.equal(shouldCommitCurl(40, 400, -1), false)
  assert.equal(shouldCommitCurl(40, 400, 0.8), true)
  assert.equal(shouldCommitCurl(160, 400, 0), true)
  assert.equal(shouldCommitCurl(160, 400, -0.8), false)
})
