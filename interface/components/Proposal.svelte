<script>
  export let post
</script>

<div class="post-preview">
  <h2>{post.id}</h2>
  <p>{post.userPrincipal.toString()}</p>
  <p>Change website text to: {post.payload}</p>
  <!-- <p>
    Yes: {(post.yesVotes / BigInt(100000000)).toString()}, No: {(
      post.noVotes / BigInt(100000000)
    ).toString()}
  </p>
  
  <p>Status: {post.status}</p> -->
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
