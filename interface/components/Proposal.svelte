<script>
  export let post
</script>

<div class="post-preview">
  <h2>{post.payload}</h2>
  <!-- <p>{post[0].userPrincipal.toString()}</p>
  <p>Change website text to: {post[0].payload}</p> -->
  <!-- <p>
    Yes: {(post[0].votes[0] / BigInt(100000000)).toString()}, No: {(
      post[0].votes[1] / BigInt(100000000)
    ).toString()}
  </p> -->
</div>

<style>
  .post-preview {
    border: 1px solid white;
    border-radius: 10px;
    margin-bottom: 2vmin;
    padding: 2vmin;
  }
  h2 {
    color: white;
  }

  /* p {
    color: white;
  } */
</style>
