using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Random = UnityEngine.Random;

namespace Collections.ParticleSystems.SpriteDisintegrate
{
    public class SpriteDeintegrateSimple : MonoBehaviour
    {
        public float particleDensity = 0.1f; // This is how tight the particle spawn in width and heigh

        // First we get some components
        private SpriteRenderer _spriteRenderer;
        private ParticleSystem _particleSystem;

        private ParticleSystem.Particle[] _particles;

        private void Awake()
        {
            _spriteRenderer = GetComponentInChildren<SpriteRenderer>();
            _particleSystem = GetComponentInChildren<ParticleSystem>();

            SpawnParticles();

            // Now we animate it
            StartCoroutine(AnimateParticles());
        }

        private IEnumerator AnimateParticles()
        {
            // Wait for 1 sec and bomb
            yield return new WaitForSeconds(1);

            // Hide the sprite renderer
            _spriteRenderer.enabled = false;

            // Fly all the particles to the right of the screen

            for (int i = 0; i < _particles.Length; i++)
            {
                // We change the velocity of all the Particles (Random velocity)
                var velocity = new Vector3
                {
                    x = Random.Range(3f, 5f),
                    y = Random.Range(-1f, 1f),
                    z = 0,
                };

                _particles[i].velocity = velocity;
            }
        
            // Apply
            _particleSystem.SetParticles(_particles);
        
            // Done for now
        }

        private void SpawnParticles()
        {
            // We get the width and height of texture;
            var sprite = _spriteRenderer.sprite;
            var texture = sprite.texture;
            var texWidth = texture.width;
            var texHeight = texture.height;

            // Now we define the exact number of particle per width and height
            var particlesAmount = new Vector2
            {
                x = Mathf.RoundToInt(texWidth * particleDensity), // amount cannot be float right ?
                y = Mathf.RoundToInt(texHeight * particleDensity),
            };

            // Now we calculate the pixel offset that we need to read on texture, because we cannot read all the pixels (too much)

            var pixelsOffset = new Vector2 // This is the distance we skip between pixels
            {
                x = texHeight / particlesAmount.x,
                y = texHeight / particlesAmount.y,
            };

            // Now read to Texture, we only need the opaque pixels (ignore transparent)
            var whitePixels = new List<Vector2>();
            for (int h = 0; h < particlesAmount.y; h++)
            {
                for (int w = 0; w < particlesAmount.x; w++)
                {
                    var x = Mathf.RoundToInt(pixelsOffset.x * w); // pixels cannot be float
                    var y = Mathf.RoundToInt(pixelsOffset.y * h); // pixels cannot be float

                    var pixelColor = texture.GetPixel(x, y);
                    if (pixelColor.a > 0.9f)
                    {
                        // Store it
                        whitePixels.Add(new Vector2(w, h));
                    }
                }
            }

            // Now we have to points to spawn Particles
            // But first we must emit
            var totalParticlesAmount = whitePixels.Count;
            _particleSystem.Emit(new ParticleSystem.EmitParams(), totalParticlesAmount);

            // And we create an arrays to store all the Particles
            _particles = new ParticleSystem.Particle[totalParticlesAmount];
            _particleSystem.GetParticles(_particles);

            // Now we set the position and color for each Particles;
            // And calculate the offset between Particles
            var particlesOffset = pixelsOffset / sprite.pixelsPerUnit;

            // Offset all The Particles to bottom
            var minPosition = sprite.bounds.min;

            for (int i = 0; i < totalParticlesAmount; i++)
            {
                var position = minPosition;
                position.x += particlesOffset.x * whitePixels[i].x;
                position.y += particlesOffset.y * whitePixels[i].y;
                position.z += 0;

                _particles[i].position = position;
                _particles[i].startColor = Color.white;
            }

            // Now we assign into Particle System
            _particleSystem.SetParticles(_particles);

            // Almost done
        }
    }
}