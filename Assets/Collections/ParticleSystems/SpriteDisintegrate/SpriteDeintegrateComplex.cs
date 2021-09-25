using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Random = UnityEngine.Random;

namespace Collections.ParticleSystems.SpriteDisintegrate
{
    public class SpriteDeintegrateComplex : MonoBehaviour
    {
        public ParticleSystem particleSample;
        public SpriteRenderer targetSpriteRenderer;
        public float density = 0.1f;

        private Texture2D _texture;
        private int _maxParticles;
        private Vector3 _minPosition;
        private ParticleSystem.Particle[] _particles;

        private void Awake()
        {
            _minPosition = targetSpriteRenderer.bounds.min;
            CloneTexture();
            CreateParticle();
        }

        private IEnumerator Start()
        {
            yield return new WaitForSeconds(2);
            AnimateParticle2();
        }

        public void CreateParticle()
        {
            var texWidth = _texture.width;
            var texHeight = _texture.height;

            var particleForWidth = Mathf.FloorToInt(texWidth * density);
            var particleForHeight = Mathf.FloorToInt(texHeight * density);

            var colors = GetTextureColorPixels(_texture, particleForWidth, particleForHeight);
            _maxParticles = colors.Count;

            _particles = new ParticleSystem.Particle[_maxParticles];
            var offset = new Vector2(texWidth / (float)particleForWidth, texHeight / (float)particleForHeight) /
                         targetSpriteRenderer.sprite.pixelsPerUnit;

            var emitParams = new ParticleSystem.EmitParams();
            particleSample.Emit(emitParams, _maxParticles);
            particleSample.GetParticles(_particles, _particles.Length);

            var index = 0;
            var color = new Color(1, 1, 1, 0);
            foreach (var c in colors)
            {
                var keyPos = c.Key;
                var pos = _minPosition;
                pos.x += offset.x * keyPos.x;
                pos.y += offset.y * keyPos.y;
                pos.z += 0.2f;

                _particles[index].position = pos;
                _particles[index].startColor = color;
                index++;
            }

            particleSample.SetParticles(_particles, _particles.Length);
            particleSample.Pause();
        }

        private void CloneTexture()
        {
            var originTexture = targetSpriteRenderer.sprite.texture;

            _texture = Instantiate(originTexture);

            var originSprite = targetSpriteRenderer.sprite;
            targetSpriteRenderer.sprite =
                Sprite.Create(_texture, new Rect(0, 0, _texture.width, _texture.height), new Vector2(0.5f, 0.5f), 100f);
        }

        public void AnimateParticle2()
        {
            StartCoroutine(AnimateParticle2Coroutine());
            targetSpriteRenderer.enabled = false;
        }

        private IEnumerator AnimateParticle2Coroutine()
        {
            var wait = new WaitForSeconds(0.05f);
            const int maxChunkSize = 40;

            particleSample.GetParticles(_particles);
            var order = GetParticlesOrder();
            yield return null;

            particleSample.Play();
            var color = Color.white;
            for (int i = 0; i < _particles.Length; i++)
            {
                var vel = Vector3.zero;
                vel.x = Random.Range(-0.5f, 0.01f);
                vel.y = Random.Range(-0.5f, 0.01f);
                _particles[i].velocity = vel;
                _particles[i].startColor = color;
            }

            particleSample.SetParticles(_particles);

            yield return new WaitForSeconds(0.2f);

            particleSample.GetParticles(_particles);
            for (var i = 0; i < order.Length; i++)
            {
                var vel = Vector3.zero;
                vel.x = Random.Range(4f, 6f);
                vel.y = Random.Range(0.5f, 2f);
                var index = order[i].ParticleIndex;
                _particles[index].velocity = vel;

                if (i % maxChunkSize == 0)
                {
                    particleSample.SetParticles(_particles);
                    yield return wait;
                    particleSample.GetParticles(_particles);
                }

                if (i == order.Length - 1)
                {
                    particleSample.SetParticles(_particles);
                }
            }

            yield return new WaitForSeconds(particleSample.main.duration);
            particleSample.Stop();
        }

        private Block[] GetParticlesOrder()
        {
            var maxPoint = targetSpriteRenderer.bounds.max;
            var order = new Block[_particles.Length];
            for (var i = 0; i < _particles.Length; i++)
            {
                var pos = _particles[i].position + maxPoint;
                // var dist = Mathf.Max(pos.x, pos.y);
                var dist = pos.sqrMagnitude;
                order[i] = new Block(i, dist);
            }

            Array.Sort(order, (a, b) => a.DistanceFromZero.CompareTo(b.DistanceFromZero));
            return order;
        }

        private void HidePixels(float percent)
        {
            var color = new Color(1, 1, 1, 0);

            var width = _texture.width;
            var height = _texture.height;

            var totalChunk = width * height;
            var maxChunkSize = totalChunk / 20;
            var chunkIndex = Mathf.CeilToInt(percent * totalChunk);

            var chunkSize = maxChunkSize;

            if (chunkIndex + chunkSize >= totalChunk)
            {
                chunkSize = totalChunk - chunkIndex;
            }

            for (var i = chunkIndex; i < chunkIndex + chunkSize; i++)
            {
                var x = i % width;
                var y = i / width;
                _texture.SetPixel(x, y, color);
            }

            _texture.Apply();
        }

        private static Dictionary<Vector2, Color> GetTextureColorPixels(Texture2D texture, int blockWidth, int blockHeight)
        {
            var dict = new Dictionary<Vector2, Color>();

            var texWidth = texture.width;
            var texHeight = texture.height;
            var offset = new Vector2(texWidth / (float)blockWidth, texHeight / (float)blockHeight);

            for (var h = 0; h < blockHeight; h++)
            {
                for (var w = 0; w < blockWidth; w++)
                {
                    var x = Mathf.RoundToInt(offset.x * w);
                    var y = Mathf.RoundToInt(offset.y * h);
                    var color = texture.GetPixel(x, y);
                    if (color.a > 0.9f)
                    {
                        dict[new Vector2(w, h)] = color;
                    }
                }
            }

            return dict;
        }

        public readonly struct Block
        {
            public readonly int ParticleIndex;
            public readonly float DistanceFromZero;

            public Block(int particleIndex, float distanceFromZero)
            {
                this.ParticleIndex = particleIndex;
                this.DistanceFromZero = distanceFromZero;
            }
        }
    }
}